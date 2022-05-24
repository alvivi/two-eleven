defmodule TwoEleven.Accounts.Player do
  @moduledoc """
  A player entity.
  """

  alias __MODULE__, as: Player

  @typedoc "The player entity structure."
  @type t :: %Player{
          id: binary(),
          emoji: String.t(),
          name: String.t(),
          token: binary()
        }

  defstruct [:id, :emoji, :name, :token]

  @doc false
  @spec dump(t()) :: tuple()
  def dump(player), do: {player.id, player.emoji, player.name, player.token}

  @doc false
  @spec load(tuple()) :: t()
  def load({id, emoji, name, token}), do: %Player{id: id, emoji: emoji, name: name, token: token}
end
