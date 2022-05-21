defmodule TwoEleven.GameState do
  @moduledoc """
  A pure, observable,
  [2048 game](https://en.wikipedia.org/wiki/2048_(video_game)) logic
  implementation.

  This module implements the rules and mechanics of the 2024 game in a
  [pure](https://en.wikipedia.org/wiki/Pure_function) and observable fashion.
  Clients of this module must hold the state of a game and `execute/2`
  [commands](https://gameprogrammingpatterns.com/command.html) to play. After
  running a command, an updated state and list of events is returned. These
  events describe the changes applied to the state, and can be used for
  implementing animations, among other things.

  The main interface function is `execute/2`, which applies a `t:command/0` to
  given [state](`t:t/0`).

  ## Creating a new game

  To create new instance of a game, the `:start` command should be used:

      {state, _events} = GameState.execute(%GameState{}, :start)

  The game itself can be configured:

      start_command = {:start, width: 4, height: 4, obstacle_count: 1}
      {state, _events} = GameState.execute(%GameState{}, start_command)

  Read `t:config/0` for more information about available options.

  ## Playing a game

  After a new instance of the game has been created, we can play the game
  executing slide commands:

      {updated_state, _events} = GameState.execute(state, :slide_right)
      {updated_state, _events} = GameState.execute(updated_state, :slide_up)

  **NOTE** that the state is passed and updated between `execute/2` calls. We can
  inspect the returned `t:events/0` or the [state](`t:t/0`) directly to check the
  state of the game:

      updated_state.won?

  """

  import Kernel, except: [apply: 2]

  alias __MODULE__, as: GameState

  @default_grid_height 6
  @default_grid_width 6
  @default_obstacle_count 0

  @typedoc """
  A [command](https://gameprogrammingpatterns.com/command.html) to execute.

  This type describe the action that the player wants to apply to the game.
  `:start` and `{:start, config()}` are used to create a new game. Check out
  `t:config/0` for all configuration options available.

  The `slide_x` commands are the main player actions, sliding tiles in the given
  direction.
  """
  @type command ::
          :slide_down
          | :slide_left
          | :slide_right
          | :slide_up
          | :start
          | {:start, config()}

  @typedoc "A representation of 2D vectors or points."
  @type vector :: {x :: integer(), y :: integer()}

  @typedoc """
  The state of the game.

  This structure holds the current state of the game. It must be edited using
  `execute/2`. Eventually, the contents of this structure could be private (i.e.,
  an `@opaque` type), so it is safer to read events instead of its contents.
  Field by field description is intentionally omitted for this reason.
  """
  @type t :: %GameState{
          height: pos_integer(),
          lost?: boolean(),
          obstacle_count: non_neg_integer(),
          seed: :rand.state(),
          tiles: map(),
          width: pos_integer(),
          won?: boolean()
        }

  @typedoc """
  The configuration of a game.

  A keyword list or a map (or any other `t:Access.t/0` container) defining
  configuration values for the game. Available options are:

    * `height`: a `t:pos_integer/0` that defines the height of the board.
      Defaults to `#{@default_grid_height}`.
    * `obstacle_count`: the number (`t:pos_integer/0`) of obstacle in the board.
      Defaults to `#{@default_obstacle_count}`.
    * `seed`: the seed (`t::rand.state/0`) to guide randomness. Seed can be
    * created using `:rand.seed/1` family functions. **NOTE** that by default a
      constant seed is used, making all new tile positions predictable.
    * `width`: a `t:pos_integer/0` that defines the width of the board. Defaults
      to `#{@default_grid_width}`.
  """
  @type config :: Access.t()

  @typedoc """
  The result of applying an `t:command/0` to a game.

  Events describe the changes of the state produced after executing a
  `t:command/0`. It can be used to observe a game.

  `:obstacle_placed` and `:tile_place` state that new obstacle or tile has been
  spawn on the board.

  `:tile_merged` and `:tile_move` define tile movements around the board.

  `:won` and `:lost` can be used to check finish conditions of the game.
  """
  @type event ::
          :lost
          | :won
          | {:obstacle_placed, position :: vector()}
          | {:seed_updated, :rand.export_state()}
          | {:tile_merged, from :: vector(), to :: vector(), new_value :: pos_integer()}
          | {:tile_moved, from :: vector(), to :: vector()}
          | {:tile_placed, position :: vector(), value :: pos_integer()}

  @typedoc "A list of `t:event/0`."
  @type events :: [event]

  defstruct height: @default_grid_height,
            lost?: false,
            obstacle_count: @default_obstacle_count,
            seed: nil,
            tiles: %{},
            width: @default_grid_width,
            won?: false

  #
  # Commands
  #

  @doc """
  Executes the given `t:command/0`.

  Given a `t:command/0` and a [game state](`t:t/0`), executes the actions
  defined by the command, producing a new updated game state and list of
  `t:event/0`.
  """
  @spec execute(t(), command() | [command()]) :: {t(), events()}
  def execute(state, commands) when is_list(commands) do
    Enum.reduce(commands, {state, []}, fn cmd, {acc_state, acc_events} ->
      {updated_state, last_events} = execute(acc_state, cmd)
      {updated_state, [last_events | acc_events]}
    end)
  end

  def execute(state, :start), do: execute(state, {:start, []})

  def execute(_state, {:start, config}) do
    %GameState{
      height: Access.get(config, :height, @default_grid_height),
      obstacle_count: Access.get(config, :obstacle_count, @default_obstacle_count),
      seed: Access.get(config, :size) || :rand.seed(:default, 0),
      width: Access.get(config, :width, @default_grid_width)
    }
    |> run(&place_random_obstacles/1)
    |> run(&place_random_tile(&1, :init))
  end

  def execute(state, :slide_down), do: do_move(state, {0, -1})
  def execute(state, :slide_left), do: do_move(state, {-1, 0})
  def execute(state, :slide_right), do: do_move(state, {1, 0})
  def execute(state, :slide_up), do: do_move(state, {0, 1})

  @spec do_move(t(), vector()) :: {t(), events()}
  defp do_move(state, delta) do
    state
    |> move_all_tiles(delta)
    |> run(&place_random_tile/2)
    |> run(&check_win_condition/1)
    |> run(&check_lose_condition/1)
  end

  # Commands - Actions

  @spec check_lose_condition(t()) :: events()
  defp check_lose_condition(%GameState{lost?: true}), do: []

  defp check_lose_condition(state = %GameState{lost?: false}) do
    any_free? =
      state.width
      |> all_positions(state.height)
      |> Enum.any?(&(!Map.has_key?(state.tiles, &1)))

    if any_free? do
      []
    else
      {_state, down_events} = move_all_tiles(state, {0, -1})
      {_state, left_events} = move_all_tiles(state, {-1, 0})
      {_state, right_events} = move_all_tiles(state, {1, 0})
      {_state, up_events} = move_all_tiles(state, {0, 1})

      case [down_events, left_events, right_events, up_events] do
        [[], [], [], []] -> [:lost]
        _other -> []
      end
    end
  end

  @spec check_win_condition(t()) :: events()
  defp check_win_condition(%GameState{won?: true}), do: []

  defp check_win_condition(state = %GameState{won?: false}) do
    state.tiles
    |> Map.values()
    |> Enum.any?(&match?({:tile, value} when value >= 2048, &1))
    |> if(do: [:won], else: [])
  end

  @spec move_all_tiles(t() | {t(), events()}, vector()) :: {t(), events()}
  defp move_all_tiles({state, _events}, delta), do: move_all_tiles(state, delta)

  defp move_all_tiles(state, delta) do
    state.tiles
    |> Enum.sort_by(&closest_to_wall(&1, delta))
    |> Enum.filter(&match?({_position, {:tile, _value}}, &1))
    |> Enum.reduce({state, []}, fn {position, {:tile, value}}, state_events ->
      run(state_events, &move_tile(&1, &2, position, value, delta))
    end)
  end

  @spec place_random_obstacles(t()) :: events()
  defp place_random_obstacles(state) do
    {positions, updated_seed} =
      state.width
      |> all_positions(state.height)
      |> Enum.to_list()
      |> take_random(state.obstacle_count, state.seed)

    seed_updated_event = {:seed_updated, :rand.export_seed_s(updated_seed)}
    obstacle_placed_events = Enum.map(positions, &{:obstacle_placed, &1})

    [seed_updated_event | obstacle_placed_events]
  end

  @spec place_random_tile(t(), events() | :init) :: events()
  defp place_random_tile(_state, []), do: []

  defp place_random_tile(state, _events_or_init) do
    state.width
    |> all_positions(state.height)
    |> Enum.reject(&Map.has_key?(state.tiles, &1))
    |> case do
      [] ->
        []

      free_slots ->
        {[position], updated_seed} = take_random(free_slots, 1, state.seed)

        [
          {:seed_updated, :rand.export_seed_s(updated_seed)},
          {:tile_placed, position, 2}
        ]
    end
  end

  @spec move_tile(t(), events(), vector(), vector() | nil, integer(), vector()) :: events()
  defp move_tile(state, events, origin, position \\ nil, value, delta)

  defp move_tile(state, events, origin, nil, value, {dx, dy}),
    do: move_tile(state, events, origin, origin, value, {dx, dy})

  defp move_tile(state, events, origin, position = {x, y}, value, delta = {dx, dy}) do
    new_position = {clamp(x + dx, 0, state.width - 1), clamp(y + dy, 0, state.height - 1)}

    recently_merged? =
      Enum.any?(events, &match?({:tile_merged, _origin, ^new_position, _value}, &1))

    case {origin, position, new_position, state.tiles[new_position], recently_merged?} do
      {_origin, constant, constant, _value, _merged?} when origin != position ->
        [{:tile_moved, origin, position}]

      {_origin, _position, _new_position, nil, _merged} when origin != new_position ->
        move_tile(state, events, origin, new_position, value, delta)

      {_origin, _position, _new_position, {:tile, ^value}, false} when origin != new_position ->
        [{:tile_merged, origin, new_position, value * 2}]

      {_origin, _position, _new_position, _value, _merged} when origin != position ->
        [{:tile_moved, origin, position}]

      _constant ->
        []
    end
  end

  # Commands - Actions - Helpers

  @spec all_positions(pos_integer(), pos_integer()) :: Enum.t()
  defp all_positions(width, height) do
    Stream.unfold({width - 1, height - 1}, fn
      {x, y} when x >= 0 and y >= 0 -> {{x, y}, {x - 1, y}}
      {_x, 0} -> nil
      {_x, y} -> {{width - 1, y - 1}, {width - 2, y - 1}}
    end)
  end

  @spec clamp(integer(), integer(), integer()) :: integer()
  defp clamp(v, min, max), do: min(max(v, min), max)

  @spec closest_to_wall({vector(), any()}, vector()) :: integer()
  defp closest_to_wall({{x, y}, _value}, {dx, dy}), do: x * -dx + y * -dy

  @spec take_random(list(), non_neg_integer(), :rand.state()) :: {list(), :rand.state()}
  defp take_random(list, count, seed)

  defp take_random(_list, 0, seed), do: {[], seed}

  defp take_random([], _cont, seed), do: {[], seed}

  defp take_random(list, count, seed) do
    {index, updated_seed} = :rand.uniform_s(length(list), seed)
    {elem, updated_list} = List.pop_at(list, index - 1)
    {acc, updated_seed} = take_random(updated_list, count - 1, updated_seed)

    {[elem | acc], updated_seed}
  end

  # Commands - Helpers

  @spec run(t() | {t(), events()}, fun()) :: {t(), events()}
  defp run({state, events}, action) do
    action
    |> run_action(state, events)
    |> Enum.reduce({state, events}, fn event, {acc_state, acc_events} ->
      {apply(acc_state, event), [event | acc_events]}
    end)
  end

  defp run(state, action), do: run({state, []}, action)

  @spec run_action(fun(), t(), events()) :: events()
  defp run_action(action, state, _events) when is_function(action, 1), do: action.(state)
  defp run_action(action, state, events) when is_function(action, 2), do: action.(state, events)

  #
  # State Mutators
  #

  @spec apply(t(), event()) :: t()
  defp apply(state, :lost), do: %GameState{state | lost?: true}
  defp apply(state, :won), do: %GameState{state | won?: true}

  defp apply(state, {:obstacle_placed, position}),
    do: %GameState{state | tiles: Map.put_new(state.tiles, position, :obstacle)}

  defp apply(state, {:seed_updated, exported_seed}),
    do: %GameState{state | seed: :rand.seed(exported_seed)}

  defp apply(state, {:tile_merged, from, to, new_value}) do
    updated_tiles =
      state.tiles
      |> Map.delete(from)
      |> Map.replace!(to, {:tile, new_value})

    %GameState{state | tiles: updated_tiles}
  end

  defp apply(state, {:tile_moved, from, to}) do
    updated_tiles =
      state.tiles
      |> Map.delete(from)
      |> Map.put_new(to, Map.fetch!(state.tiles, from))

    %GameState{state | tiles: updated_tiles}
  end

  defp apply(state, {:tile_placed, position, value}),
    do: %GameState{state | tiles: Map.put_new(state.tiles, position, {:tile, value})}

  #
  # Misc Helpers
  #

  @doc false
  @spec sigil_G(String.t(), keyword()) :: t()
  def sigil_G(string, _modifiers) do
    cells = parse_cells(string)
    {{last_x, last_y}, _cell} = List.last(cells)
    obstacle_count = cells |> Enum.filter(&match?({_position, :obstacle}, &1)) |> length()

    tiles =
      cells
      |> Enum.reject(&match?({_position, nil}, &1))
      |> Map.new()

    %GameState{
      height: last_y + 1,
      obstacle_count: obstacle_count,
      seed: :rand.seed(:default),
      tiles: tiles,
      width: last_x + 1
    }
  end

  @spec parse_cells(String.t()) :: list()
  defp parse_cells(string) do
    string
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&(&1 |> String.split("|") |> Enum.with_index()))
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.map(fn {line, y} ->
      Enum.map(line, fn {cell, x} ->
        # credo:disable-for-next-line Credo.Check.Refactor.Nesting
        case String.trim(cell) do
          "" ->
            {{x, y}, nil}

          "X" ->
            {{x, y}, :obstacle}

          binary ->
            {value, ""} = Integer.parse(binary)
            {{x, y}, {:tile, value}}
        end
      end)
    end)
    |> Enum.concat()
  end
end

defimpl Inspect, for: TwoEleven.GameState do
  @moduledoc false

  import Inspect.Algebra

  alias TwoEleven.GameState

  @spec inspect(GameState.t(), Inspect.Opts.t()) :: Inspect.Algebra.t()
  def inspect(state, _opts) do
    length =
      state.tiles
      |> Map.values()
      |> Enum.filter(&match?({:tile, _value}, &1))
      |> Enum.map(&elem(&1, 1))
      |> Enum.max()
      |> to_string()
      |> String.length()

    lines =
      for y <- (state.height - 1)..0 do
        for x <- 0..(state.width - 1), reduce: "" do
          "" -> format_tile(state.tiles[{x, y}], length)
          acc -> acc <> " | " <> format_tile(state.tiles[{x, y}], length)
        end
      end

    lines
    |> Enum.intersperse(line())
    |> concat()
  end

  defp format_tile(nil, length), do: String.duplicate(" ", length)
  defp format_tile({:tile, value}, length), do: String.pad_leading(to_string(value), length)
  defp format_tile(:obstacle, length), do: String.pad_leading("X", length)
end
