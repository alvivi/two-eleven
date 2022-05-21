defmodule TwoEleven.GameStateTest do
  use ExUnit.Case, async: true
  use PropCheck

  import TwoEleven.GameState, only: [sigil_G: 2]

  alias TwoEleven.GameState

  @max_width 64
  @max_height 64
  @max_obstacle_count 32

  describe "Statement examples" do
    test "first scenario" do
      initial_state = ~G"""
          |   | 2 |   |   | 2
          | 2 |   |   |   |
          |   |   |   |   |
          | 4 |   |   |   | 2
          |   |   | 2 |   |
          |   |   |   |   |
      """

      {given_state, events} = GameState.execute(initial_state, :slide_right)
      given_tiles = remove_placed_tiles(given_state, events)

      expected_state = ~G"""
          |   |   |   |   | 4
          |   |   |   |   | 2
          |   |   |   |   |
          |   |   |   | 4 | 2
          |   |   |   |   | 2
          |   |   |   |   |
      """

      assert given_tiles == expected_state.tiles
    end

    test "second scenario" do
      initial_state = ~G"""
          |   | 2 |   |   | 2
          | 2 |   |   |   |
          |   |   |   |   |
          | 4 |   |   |   | 2
          |   |   | 2 |   |
          |   |   |   |   |
      """

      {given_state, events} = GameState.execute(initial_state, :slide_up)
      given_tiles = remove_placed_tiles(given_state, events)

      expected_state = ~G"""
          | 2 | 2 | 2 |   | 4
          | 4 |   |   |   |
          |   |   |   |   |
          |   |   |   |   |
          |   |   |   |   |
          |   |   |   |   |
      """

      assert given_tiles == expected_state.tiles
    end

    test "third scenario" do
      initial_state = ~G"""
          |   | 2 |   |   | 2
          | 2 |   |   |   |
          |   |   |   |   |
          | 4 |   |   |   | 4
          |   |   | 2 |   |
        8 |   |   |   | 8 |
      """

      {given_state, events} = GameState.execute(initial_state, :slide_left)
      given_tiles = remove_placed_tiles(given_state, events)

      expected_state = ~G"""
         4 |    |    |    |    |
         2 |    |    |    |    |
           |    |    |    |    |
         8 |    |    |    |    |
         2 |    |    |    |    |
        16 |    |    |    |    |
      """

      assert given_tiles == expected_state.tiles
    end

    test "fourth scenario" do
      initial_state = ~G"""
           |    |  2 |    | 16 |  2
           |  2 |    |    |    |
         4 |  2 |    |    |    |
         4 |    |    |    |    |  4
           |    |    |  2 |  8 |
         8 |  2 |    |    |  8 |
      """

      {given_state, events} = GameState.execute(initial_state, :slide_down)
      given_tiles = remove_placed_tiles(given_state, events)

      expected_state = ~G"""
           |    |    |    |    |
           |    |    |    |    |
           |    |    |    |    |
           |    |    |    |    |
         8 |  2 |    |    | 16 |  2
         8 |  4 |  2 |  2 | 16 |  4
      """

      assert given_tiles == expected_state.tiles
    end

    test "fifth scenario" do
      initial_state = ~G"""
              |      |    2 |   16 |   16 |    2
              |    2 | 1024 |      |    X | 1024
              |      |      |      |      |
            4 |      |      |      |    4 |    2
           32 |      |    X |    2 |      |   64
              |      |      |      |      |
      """

      {given_state, events} = GameState.execute(initial_state, :slide_right)
      given_tiles = remove_placed_tiles(given_state, events)

      expected_state = ~G"""
              |      |      |    2 |   32 |    2
              |      |    2 | 1024 |    X | 1024
              |      |      |      |      |
              |      |      |      |    8 |    2
              |   32 |    X |      |    2 |   64
              |      |      |      |      |
      """

      assert given_tiles == expected_state.tiles
    end
  end

  describe "Finish conditions" do
    test "won event is produced after merging a tile with 2048 value" do
      initial_state = ~G"""
              |      |      |      |      |
              |      |      |      |      |
              |      |      |      |      |
              |      |      |      |      |
              |      |      |      |    2 |    2
              |      |      |    2 | 1024 | 1024
      """

      {_given_state, events} = GameState.execute(initial_state, :slide_right)

      assert Enum.any?(events, &match?(:won, &1))
    end

    test "lost event is produced when no new tile can be placed" do
      initial_state = ~G"""
            2 |    4 |    8 |   16 |   32 |   64
            4 |    8 |   16 |   32 |   64 |  128
            8 |   16 |   32 |   64 |  128 |  256
           16 |   32 |   64 |  128 |  256 |  512
           32 |   64 |  128 |  256 |  512 | 1024
           64 |  128 |  256 |  512 | 1024 | 2048
      """

      {_given_state, events} = GameState.execute(initial_state, :slide_up)
      assert Enum.any?(events, &match?(:lost, &1))

      {_given_state, events} = GameState.execute(initial_state, :slide_right)
      assert Enum.any?(events, &match?(:lost, &1))

      {_given_state, events} = GameState.execute(initial_state, :slide_down)
      assert Enum.any?(events, &match?(:lost, &1))

      {_given_state, events} = GameState.execute(initial_state, :slide_left)
      assert Enum.any?(events, &match?(:lost, &1))
    end

    test "lost event is not produced if a slide allow a tile placement" do
      initial_state = ~G"""
            2 |    4 |    8 |   16 |   32 |   64
            4 |    8 |   16 |   32 |   64 |  128
            8 |   16 |   32 |   64 |  128 |  256
           16 |   32 |   64 |  128 |  256 |  512
           32 |   64 |  128 |  256 |  512 | 2048
           64 |  128 |  256 |  512 | 1024 | 2048
      """

      {_given_state, events} = GameState.execute(initial_state, :slide_right)
      refute Enum.any?(events, &match?(:lost, &1))
    end
  end

  describe "Invariants" do
    property "tiles never go off the board" do
      forall [{initial_state, initial_events} <- started_game(), cmds <- slides()] do
        {_final_state, events} = GameState.execute(initial_state, cmds)

        any_tile_out? =
          initial_events
          |> Stream.concat(events)
          |> Stream.map(fn
            {:tile_merged, from, to, _value} -> [from, to]
            {:tile_moved, from, to} -> [from, to]
            {:tile_placed, pos, _value} -> [pos]
            _other -> [nil]
          end)
          |> Stream.concat()
          |> Stream.reject(&is_nil/1)
          |> Enum.any?(fn {x, y} ->
            x < 0 or y < 0 or x >= initial_state.width or y >= initial_state.height
          end)

        !any_tile_out?
      end
    end

    property "obstacles do not change nor move" do
      forall [{initial_state, _initial_events} <- started_game(), cmds <- slides()] do
        {final_state, _events} = GameState.execute(initial_state, cmds)

        expected_obstacle =
          initial_state.tiles
          |> Enum.filter(&match?({_position, :obstacles}, &1))
          |> Enum.sort()

        given_obstacles =
          final_state.tiles
          |> Enum.filter(&match?({_position, :obstacles}, &1))
          |> Enum.sort()

        expected_obstacle == given_obstacles
      end
    end
  end

  defp remove_placed_tiles(state, events) do
    events
    |> Enum.filter(&match?({:tile_placed, _position, _value}, &1))
    |> Enum.map(fn {:tile_placed, position, _value} -> position end)
    |> Enum.reduce(state.tiles, &Map.delete(&2, &1))
  end

  def slides, do: list(slide())

  def slide do
    ~w(slide_down slide_left slide_right slide_up)a
    |> union()
    |> noshrink()
  end

  def started_game do
    let [
      height <- integer(1, @max_height),
      obstacle_count <- integer(0, @max_obstacle_count),
      width <- integer(1, @max_width)
    ] do
      start_cmd = {:start, height: height, obstacle_count: obstacle_count, width: width}
      GameState.execute(%GameState{}, start_cmd)
    end
  end
end
