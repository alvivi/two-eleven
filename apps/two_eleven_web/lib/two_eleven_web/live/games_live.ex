defmodule TwoElevenWeb.GamesLive do
  @moduledoc false

  use TwoElevenWeb, :live_view

  alias TwoEleven.{Arenas, GameState}

  @default_board_height 6
  @default_board_obstacles 0
  @default_board_width 6

  @keys_mapping %{
    "ArrowDown" => :down,
    "ArrowLeft" => :left,
    "ArrowRight" => :right,
    "ArrowUp" => :up
  }

  @supported_keys Map.keys(@keys_mapping)

  #
  # Initialization
  #

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:board_height, @default_board_height)
      |> assign(:board_obstacles, @default_board_obstacles)
      |> assign(:board_width, @default_board_width)
      |> assign(:current_games, [])
      |> assign(:game_id, nil)
      |> assign(:game_state, nil)
      |> assign(:just_won?, false)
      |> assign(:lost?, false)
      |> assign(:message, "")
      |> assign(:messages, [])
      |> assign(:moved?, false)
      |> assign(:player_games, [])

    {:ok, socket, temporary_assigns: [messages: []]}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @spec apply_action(Socket.t(), atom(), map()) :: Socket.t()
  defp apply_action(socket, :index, _params) do
    player_id = socket.assigns.player.id
    player_token = socket.assigns.player.token

    current_games =
      Enum.reject(Arenas.get_current_games_summary(), &match?(%{owner: %{id: ^player_id}}, &1))

    {:ok, player_games} = Arenas.get_player_games_summary(player_id, player_token)

    socket
    |> assign(:current_games, current_games)
    |> assign(:player_games, player_games)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:game_id, nil)
    |> assign(:game_state, nil)
    |> assign(:message, "")
    |> assign(:messages, [])
    |> assign(:page_title, "New Game")
  end

  defp apply_action(socket, :show, %{"id" => game_id}) do
    socket =
      if connected?(socket) do
        socket_game_id = socket.assigns[:game_id]

        if socket_game_id != nil and socket_game_id != game_id do
          {:ok, topic} = Arenas.unsubscribe(socket.assigns.game_id)
          TwoElevenWeb.Presence.untrack(self(), topic, socket.id)
        end

        {:ok, topic} = Arenas.subscribe(game_id)

        meta = %{player_id: socket.assigns.player.id}
        TwoElevenWeb.Presence.track(self(), topic, socket.id, meta)

        assign(socket, :game_topic, topic)
      else
        socket
      end

    game_state = Arenas.get_game_state(game_id)

    initial_events =
      game_state.tiles
      |> tiles_to_events()
      |> Enum.map(&dump_event/1)

    socket
    |> assign(:board_height, game_state.height)
    |> assign(:board_width, game_state.width)
    |> assign(:game_id, game_id)
    |> assign(:game_state, game_state)
    |> assign(:lost?, game_state.lost?)
    |> assign(:message, "")
    |> assign(:messages, [])
    |> assign(:page_title, "Playing #{game_id}")
    |> push_event("apply-board-events", %{"events" => initial_events})
    |> push_event("focus", %{"selector" => "#game-board"})
  end

  #
  # UI Events
  #

  def handle_event("message-input-blur", %{"value" => message}, socket) do
    {:noreply, assign(socket, :message, message)}
  end

  def handle_event("send-message", %{"message" => %{"text" => message_text}}, socket) do
    with game_id when not is_nil(game_id) <- socket.assigns.game_id,
         text when text != "" <- String.trim(message_text) do
      Arenas.send_message(
        game_id,
        socket.assigns.player.id,
        socket.assigns.player.token,
        text
      )
    end

    {:noreply, assign(socket, :message, "")}
  end

  @impl true
  def handle_event("slide", %{"key" => key}, socket) when key in @supported_keys do
    Arenas.slide_game(socket.assigns.game_id, Map.fetch!(@keys_mapping, key))

    socket =
      socket
      |> assign(:moved?, true)
      |> assign(:just_won?, false)

    {:noreply, socket}
  end

  def handle_event("slide", _payload, socket), do: {:noreply, socket}

  def handle_event("start-new-game", %{"game" => params}, socket) do
    width = cast_integer(params["width"], @default_board_width)
    height = cast_integer(params["height"], @default_board_height)
    obstacles = cast_integer(params["obstacles"], @default_board_obstacles)

    player_id = socket.assigns.player.id
    player_token = socket.assigns.player.token

    {:ok, game_id} = Arenas.new_game(player_id, player_token)
    Arenas.start_game(game_id, width: width, height: height, obstacle_count: obstacles)
    path = Routes.games_path(socket, :show, game_id)

    Arenas.get_player_games_summary(player_id, player_token)

    {:noreply, push_patch(socket, to: path, replace: true)}
  end

  #
  # Arena Events
  #

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    {:noreply, socket}
  end

  def handle_info(%{event: "game_state_diff", payload: events}, socket) do
    socket =
      events
      |> Enum.reverse()
      |> Enum.map(&dump_event/1)
      |> Enum.reject(&is_nil/1)
      |> then(&push_event(socket, "apply-board-events", %{"events" => &1}))

    socket = assign(socket, :just_won?, Enum.any?(events, &match?(:won, &1)))

    {:noreply, socket}
  end

  def handle_info(%{event: "message_sent", payload: payload}, socket) do
    socket = update(socket, :messages, &[payload | &1])

    {:noreply, socket}
  end

  #
  # Index Rendering
  #

  @spec game_link(map()) :: Rendered.t()
  defp game_link(assigns) do
    assigns = assign_new(assigns, :show_owner, fn -> "false" end)

    ~H"""
    <UI.button action="patch" to={@path} replace="true">
      <div class="flex flex-row space-x-2">
        <%= if @show_owner == "true" do %>
          <UI.player_tag
            name={@game.owner.name}
            emoji={@game.owner.emoji}
            class="text-xl"
            hide_name="true"
          />
        <% end %>
        <div class="flex flex-col">
          <span><strong>Game</strong>: <%= @game.game_id %></span>
          <span>
            <strong>Size</strong>: <%= @game.width %> ✕ <%= @game.height %>
          </span>
          <span><strong>Obstacles</strong>: <%= @game.obstacles %></span>
        </div>
      </div>
    </UI.button>
    """
  end

  #
  # Board Rendering
  #

  @spec dump_event(GameState.event()) :: map() | nil
  defp dump_event({:obstacle_placed, {x, y}}), do: %{type: "obstacle-placed", to: %{x: x, y: y}}

  defp dump_event({:tile_merged, {from_x, from_y}, {to_x, to_y}, value}) do
    %{
      type: "tile-merged",
      from: %{x: from_x, y: from_y},
      to: %{x: to_x, y: to_y},
      value: value
    }
  end

  defp dump_event({:tile_moved, {from_x, from_y}, {to_x, to_y}}),
    do: %{type: "tile-moved", from: %{x: from_x, y: from_y}, to: %{x: to_x, y: to_y}}

  defp dump_event({:tile_placed, {x, y}, value}),
    do: %{type: "tile-placed", to: %{x: x, y: y}, value: value}

  defp dump_event(_event), do: nil

  @spec tiles_to_events(map()) :: GameState.events()
  defp tiles_to_events(tiles) do
    Enum.map(tiles, fn
      {{x, y}, {:tile, value}} -> {:tile_placed, {x, y}, value}
      {{x, y}, :obstacle} -> {:obstacle_placed, {x, y}}
    end)
  end

  #
  # Misc Helpers
  #

  @spec cast_integer(binary() | nil, integer()) :: integer()
  defp cast_integer(nil, default), do: default

  defp cast_integer(binary, default) do
    case Integer.parse(binary) do
      {value, ""} -> value
      _other -> default
    end
  end

  @spec map_swap!(map(), Map.key(), Map.key()) :: map() | no_return()
  defp map_swap!(map, from, to) do
    {value, map} = Map.pop!(map, from)
    Map.put(map, to, value)
  end
end
