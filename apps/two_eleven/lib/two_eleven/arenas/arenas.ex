defmodule TwoEleven.Arenas do
  @moduledoc """
  The [context](https://hexdocs.pm/phoenix/contexts.html) that manages arenas.

  Arenas instances of [games](`TwoEleven.GameState`), which can be played by
  several user at the same time.
  """

  alias Phoenix.PubSub
  alias TwoEleven.{Accounts, Arenas.Game, GameState}
  alias TwoEleven.Helpers.Id

  @default_max_retries 31

  @tab_ids Module.concat(__MODULE__, Tables.GamesById)
  @tab_players Module.concat(__MODULE__, Tables.GamesByPlayer)

  @doc false
  @spec init(keyword()) :: :ok
  def init(opts \\ []) do
    reset? = Keyword.get(opts, :reset, false)

    if :ets.info(@tab_ids) != :undefined and reset? do
      :ets.delete(@tab_ids)
    end

    if :ets.info(@tab_players) != :undefined and reset? do
      :ets.delete(@tab_players)
    end

    :ets.new(@tab_ids, [:named_table, :public])
    :ets.new(@tab_players, [:named_table, :public, :bag])

    :ok
  end

  @doc "Returns the current game state."
  @spec get_game_state(binary()) :: GameState.t() | no_return()
  def get_game_state(id) do
    :ok = ensure_game_process(id)

    Game.get_state(id)
  end

  @doc "Returns a list of game currently being played."
  @spec get_current_games_summary :: list()
  def get_current_games_summary do
    TwoEleven.Arenas.Supervisor
    |> DynamicSupervisor.which_children()
    |> Stream.map(&elem(&1, 1))
    |> Stream.map(&Registry.keys(TwoEleven.Arenas.Registry, &1))
    |> Stream.concat()
    |> Enum.map(&build_game_summary/1)
  end

  @doc "Returns a list of the player's games."
  @spec get_player_games_summary(binary(), binary()) :: {:ok, list()} | :error
  def get_player_games_summary(player_id, player_token) do
    with {:ok, player} <- Accounts.fetch_player(player_id, player_token) do
      do_get_player_games_summary(player)
    end
  end

  @spec do_get_player_games_summary(Accounts.Player.t()) :: {:ok, list()} | :error
  defp do_get_player_games_summary(player) do
    game_ids =
      @tab_players
      |> :ets.lookup(player.id)
      |> Stream.map(fn {_player_id, game_id} -> game_id end)
      |> Stream.map(&build_game_summary/1)
      |> Enum.reject(&is_nil/1)

    {:ok, game_ids}
  end

  @spec build_game_summary(binary() | list()) :: map() | nil
  defp build_game_summary(game_id) do
    case :ets.lookup(@tab_ids, game_id) do
      [{^game_id, player_id, events}] ->
        config =
          case Enum.find(events, &match?({:config_changed, _w, _h, _obs}, &1)) do
            {:config_changed, width, height, obstacles} ->
              %{width: width, height: height, obstacles: obstacles}

            nil ->
              %{}
          end

        owner =
          with player_id when not is_nil(player_id) <- player_id,
               [player_info] <- Accounts.get_display_info([player_id]) do
            player_info
          else
            _not_found -> %{}
          end

        won? = Enum.any?(events, &match?(:won, &1))
        lost? = Enum.any?(events, &match?(:lost, &1))

        Map.merge(config, %{game_id: game_id, owner: owner, won?: won?, lost?: lost?})

      _not_found ->
        nil
    end
  end

  @doc """
  Creates new game instance.

  This function only reserves an id for a new game. The `TwoEleven.GameState`
  itself is not started and `start_game/2` should be called explicitly.
  """
  @spec new_game(binary(), binary(), integer()) :: {:ok, binary()} | :error
  def new_game(player_id, player_token, retries \\ @default_max_retries)

  def new_game(player_id, player_token, retries) do
    with {:ok, player} <- Accounts.fetch_player(player_id, player_token) do
      do_new_game(player, retries)
    end
  end

  @spec do_new_game(Accounts.Player.t(), integer()) :: {:ok, binary()} | :error
  defp do_new_game(_player, retries) when retries < 0, do: :error

  defp do_new_game(player, retries) do
    game_id = Id.new()

    case :ets.insert_new(@tab_ids, {game_id, player.id, []}) do
      false ->
        do_new_game(player, retries - 1)

      true ->
        :ets.insert(@tab_players, {player.id, game_id})
        {:ok, game_id}
    end
  end

  @doc """
  Send a chat message to the given game.
  """
  @spec send_message(binary(), binary, binary(), String.t()) :: :ok | :error
  def send_message(game_id, user_id, user_token, message) do
    with {:ok, player} <- Accounts.fetch_player(user_id, user_token) do
      pubsub_event = %{
        event: "message_sent",
        payload: %{
          id: "#{game_id}-#{user_id}-#{Id.new()}",
          text: message,
          player_name: player.name,
          player_emoji: player.emoji
        }
      }

      PubSub.broadcast!(TwoEleven.PubSub, "game:#{game_id}", pubsub_event)
    end
  end

  @doc """
  Starts and configures a new game.

  Check out [`:start` command](`t:TwoEleven.GameState.command/0`) for more
  information.
  """
  @spec start_game(binary(), GameState.config()) :: GameState.events() | no_return()
  def start_game(game_id, config \\ [])

  def start_game(game_id, config) do
    config = Keyword.put_new_lazy(config, :seed, fn -> :rand.seed(:default) end)
    execute(game_id, {:start, config})
  end

  @doc """
  Performs an slide on the given game board.

  Check out [`:slide_` commands](`t:TwoEleven.GameState.command/0`) for more
  information.
  """
  @spec slide_game(binary(), atom()) :: GameState.events() | no_return()
  def slide_game(game_id, :down), do: execute(game_id, :slide_down)
  def slide_game(game_id, :left), do: execute(game_id, :slide_left)
  def slide_game(game_id, :right), do: execute(game_id, :slide_right)
  def slide_game(game_id, :up), do: execute(game_id, :slide_up)

  @doc "Subscribes to the events the given game"
  @spec subscribe(binary(), keyword()) :: {:ok, binary()} | {:error, term()}
  def subscribe(game_id, opts \\ []) do
    topic = "game:#{game_id}"
    PubSub.subscribe(TwoEleven.PubSub, topic, opts)

    {:ok, topic}
  end

  @doc "Unsubscribes to the events the given game"
  @spec unsubscribe(binary()) :: {:ok, binary()}
  def unsubscribe(game_id) do
    topic = "game:#{game_id}"
    PubSub.unsubscribe(TwoEleven.PubSub, topic)

    {:ok, topic}
  end

  @doc false
  @spec handle_events(binary(), GameState.events(), term()) :: :ok
  def handle_events(game_id, new_events, _meta) do
    [{^game_id, player_id, stored_events}] = :ets.lookup(@tab_ids, game_id)
    :ets.insert(@tab_ids, {game_id, player_id, Enum.concat(new_events, stored_events)})

    pubsub_event = %{
      event: "game_state_diff",
      payload: new_events
    }

    PubSub.broadcast!(TwoEleven.PubSub, "game:#{game_id}", pubsub_event)

    :ok
  end

  @spec execute(binary(), GameState.command()) :: GameState.events()
  defp execute(id, cmd) do
    :ok = ensure_game_process(id)
    Game.execute(id, cmd)
  end

  @spec ensure_game_process(binary()) :: :ok
  defp ensure_game_process(id) do
    if Enum.empty?(Registry.lookup(TwoEleven.Arenas.Registry, id)) do
      events =
        case :ets.lookup(@tab_ids, id) do
          [{^id, _player_id, events_list}] ->
            events_list |> Enum.reverse()

          [] ->
            :ets.insert(@tab_ids, {id, nil, []})
            []
        end

      {:ok, _pid} = start_game_process(id, events)

      :ok
    else
      :ok
    end
  end

  @spec start_game_process(binary(), GameState.events()) :: {:ok, pid()} | :error
  defp start_game_process(id, events) do
    child_spec = {Game, id: id, events: events, events_handler: {__MODULE__, :handle_events, []}}

    case DynamicSupervisor.start_child(TwoEleven.Arenas.Supervisor, child_spec) do
      {:ok, pid} -> {:ok, pid}
      {:ok, pid, _info} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      _error -> :error
    end
  end
end
