defmodule TwoEleven.Arenas.GameTest do
  use ExUnit.Case, async: true

  alias TwoEleven.Arenas.Game
  alias TwoEleven.GameState

  test "shutdowns after after a period of inactivity" do
    pid = start_supervised!({Game, id: "foo", timeout: 1}, restart: :temporary)
    monitor_ref = Process.monitor(pid)

    assert_receive {:DOWN, ^monitor_ref, :process, ^pid, :normal}
  end

  test "applies the given init events" do
    {expected_state, given_events} = GameState.execute(:start)
    start_supervised!({Game, id: "foo", events: given_events})
    given_state = Game.get_state("foo")

    assert expected_state.tiles == given_state.tiles
    assert expected_state.width == given_state.width
    assert expected_state.height == given_state.height
  end

  test "the given events_handler is executed after executing commands" do
    {parent, ref} = {self(), make_ref()}

    handler = fn id, events, meta ->
      assert id == "foo"
      refute Enum.empty?(events)
      assert meta == "bar"

      send(parent, {ref, :handler_executed})
    end

    start_supervised!({Game, id: "foo", events_handler: handler})

    Game.execute("foo", :start, "bar")

    assert_receive {^ref, :handler_executed}
  end
end
