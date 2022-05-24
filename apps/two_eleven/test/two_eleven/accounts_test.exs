defmodule TwoEleven.AccountsTest do
  use ExUnit.Case

  alias TwoEleven.Accounts

  setup :reset_accounts_database

  describe "new_player/1" do
    test "creates a fetchable player" do
      assert {:ok, player} = Accounts.new_player()
      assert {:ok, player} == Accounts.fetch_player(player.id, player.token)
    end

    test "returns an error if the maximum number of retries is reached" do
      assert :error = Accounts.new_player(-1)
    end
  end

  describe "fetch_player/2" do
    test "fetches a created player" do
      assert {:ok, player} = Accounts.new_player()
      assert {:ok, player} == Accounts.fetch_player(player.id, player.token)
    end

    test "returns an error if the user does not exists" do
      assert :error == Accounts.fetch_player("foo", "bar")
    end

    test "returns an error when token is invalid" do
      assert {:ok, player} = Accounts.new_player()
      assert :error == Accounts.fetch_player(player.id, "foo")
    end
  end

  defp reset_accounts_database(_context), do: Accounts.init(reset: true)
end
