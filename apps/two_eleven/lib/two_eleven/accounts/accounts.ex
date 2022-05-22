defmodule TwoEleven.Accounts do
  @moduledoc """
  The [context](https://hexdocs.pm/phoenix/contexts.html) that manages players.

  **NOTE** the current implementation uses [ets](`:ets`) as database, and hence,
  this implementation is ephemeral.

  **NOTE** the current implementation uses a simplistic authentication,
  mechanism, not suitable for production environments.
  """

  alias TwoEleven.Accounts.Player
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

  @doc """
  Creates a new player.

  All player information returned is initialized randomly.
  """
  @spec new_player(integer()) :: {:ok, Player.t()} | :error
  def new_player(retries \\ @default_max_retries)

  def new_player(retries) when retries < 0, do: :error

  def new_player(retries) do
    player_id = Id.new()
    player_name = Id.to_name(player_id)
    player = %Player{id: player_id, name: player_name, token: Id.new()}

    case :ets.insert_new(__MODULE__, Player.dump(player)) do
      true -> {:ok, player}
      false -> new_player(retries - 1)
    end
  end

  @doc """
  Returns player authoritative information.

  Given a user
  """
  @spec fetch_player(binary(), binary()) :: {:ok, Player.t()} | :error
  def fetch_player(id, token) do
    case :ets.lookup(__MODULE__, id) do
      [payload] ->
        player = Player.load(payload)
        if player.token == token, do: {:ok, player}, else: :error

      _other ->
        :error
    end
  end
end
