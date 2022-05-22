defmodule TwoEleven.Arenas.Game do
  @moduledoc false

  # NOTE: events_handler option is used to set a function to be run
  # synchronously when new events are produced. This avoids race conditions when
  # dealing with produced events in a concurrent system.

  use GenServer

  alias TwoEleven.GameState

  require Logger

  @default_timeout :timer.minutes(30)

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(args) do
    init_args = Keyword.take(args, ~w(id events events_handler timeout)a)
    id = Keyword.fetch!(init_args, :id)

    GenServer.start_link(__MODULE__, init_args, name: get_name(id))
  end

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(args) do
    %{
      id: {__MODULE__, Keyword.fetch!(args, :id)},
      start: {__MODULE__, :start_link, [args]},
      restart: :transient
    }
  end

  @spec get_state(binary()) :: GameState.t() | no_return()
  def get_state(id), do: GenServer.call(get_name(id), :get_state)

  @spec execute(binary(), GameState.command(), term()) :: GameState.events() | no_return()
  def execute(id, cmd, meta \\ []), do: GenServer.call(get_name(id), {:execute, cmd, meta})

  @impl true
  def init(init_args) do
    id = Keyword.fetch!(init_args, :id)
    events = Keyword.get(init_args, :events, [])
    handler = Keyword.get(init_args, :events_handler, &Function.identity/1)
    timeout = Keyword.get(init_args, :timeout, @default_timeout)
    game_state = GameState.apply(%GameState{}, events)

    initial_state = %{
      events: events,
      game_state: game_state,
      handler: handler,
      id: id,
      timeout: timeout
    }

    Logger.info("Game instance #{id} initiated")

    {:ok, initial_state, timeout}
  end

  @impl true
  def handle_info(:timeout, state) do
    Logger.info("Game instance #{state.id} terminated due to inactivity")

    {:stop, :normal, state}
  end

  @impl true
  def handle_call(:get_state, _from, state), do: {:reply, state.game_state, state, state.timeout}

  def handle_call({:execute, cmds, meta}, _from, state) do
    {updated_game_state, events} = GameState.execute(state.game_state, cmds)
    updated_state = %{state | game_state: updated_game_state}

    run_handler(state.handler, state.id, events, meta)

    Logger.debug("Game instance #{state.id} executed: #{inspect(cmds)}")

    {:reply, events, updated_state, state.timeout}
  end

  @spec get_name(binary()) :: tuple()
  defp get_name(id), do: {:via, Registry, {TwoEleven.Arenas.Registry, id}}

  @spec run_handler(fun() | {module(), atom(), list()}, binary(), term(), term()) :: term()
  defp run_handler(fun, _id, events, _meta) when is_function(fun, 1), do: fun.(events)
  defp run_handler(fun, id, events, meta) when is_function(fun, 3), do: fun.(id, events, meta)

  defp run_handler({mod, fun, args}, id, events, meta),
    do: apply(mod, fun, Enum.concat([id, events, meta], args))
end
