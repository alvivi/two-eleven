defmodule TwoEleven.Arenas do
  @moduledoc """
  The [context](https://hexdocs.pm/phoenix/contexts.html) that manages arenas.

  Arenas instances of [games](`TwoEleven.GameState`), which can be played by
  several user at the same time.
  """

  alias Phoenix.PubSub
  alias TwoEleven.Arenas.Game
  alias TwoEleven.GameState
  alias TwoEleven.Helpers.Id

  @default_max_retries 31

  @doc false
  @spec init(keyword()) :: :ok
  def init(opts \\ []) do
    if :ets.info(__MODULE__) != :undefined and Keyword.get(opts, :reset, false) do
      :ets.delete(__MODULE__)
    end

    :ets.new(__MODULE__, [:named_table, :public])

    :ok
  end

  @doc "Returns the current game state."
  @spec get_game_state(binary()) :: GameState.t() | no_return()
  def get_game_state(id) do
    :ok = ensure_game_process(id)

    Game.get_state(id)
  end

  @doc """
  Creates new game instance.

  This function only reserves an id for a new game. The `TwoEleven.GameState`
  itself is not started and `start_game/2` should be called explicitly.
  """
  @spec new_game(integer()) :: {:ok, binary()} | :error
  def new_game(retries \\ @default_max_retries)

  def new_game(retries) when retries < 0, do: :error

  def new_game(retries) do
    game_id = Id.new()

    case :ets.insert_new(__MODULE__, {game_id, []}) do
      false -> new_game(retries - 1)
      true -> {:ok, game_id}
    end
  end

  @doc """
  Starts and configures a new game.

  Check out [`:start` command](`t:TwoEleven.GameState.command/0`) for more
  information.
  """
  @spec start_game(binary(), GameState.config()) :: GameState.events() | no_return()
  def start_game(game_id, config \\ [])
  def start_game(game_id, []), do: execute(game_id, :start)
  def start_game(game_id, config), do: execute(game_id, {:start, config})

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
  @spec subscribe(binary()) :: :ok | {:error, term()}
  def subscribe(game_id), do: Phoenix.PubSub.subscribe(TwoEleven.PubSub, "game:#{game_id}")

  @doc false
  @spec handle_events(binary(), GameState.events(), term()) :: :ok
  def handle_events(game_id, new_events, _meta) do
    [{^game_id, stored_events}] = :ets.lookup(__MODULE__, game_id)
    :ets.insert(__MODULE__, {game_id, Enum.concat(new_events, stored_events)})

    PubSub.broadcast!(TwoEleven.PubSub, "game:#{game_id}", new_events)

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
        case :ets.lookup(__MODULE__, id) do
          [{^id, events_list}] ->
            events_list |> Enum.reverse()

          [] ->
            :ets.insert(__MODULE__, {id, []})
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
