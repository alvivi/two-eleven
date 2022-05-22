defmodule TwoEleven.Accounts.Player do
  @moduledoc """
  A player entity.
  """

  alias __MODULE__, as: Player

  @typedoc "The player entity structure."
  @type t :: %Player{
          id: binary(),
          name: String.t(),
          token: binary()
        }

  defstruct [:id, :name, :token]

  @doc false
  @spec dump(t()) :: tuple()
  def dump(player), do: {player.id, player.name, player.token}

  @doc false
  @spec load(tuple()) :: t()
  def load({id, name, token}), do: %Player{id: id, name: name, token: token}
end
