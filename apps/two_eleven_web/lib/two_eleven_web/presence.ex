defmodule TwoElevenWeb.Presence do
  use Phoenix.Presence,
    otp_app: :two_eleven,
    pubsub_server: TwoEleven.PubSub

  @impl true
  def fetch(_topic, presences) do
    player_info =
      presences
      |> Map.values()
      |> Enum.map(fn
        %{metas: metas} -> metas |> Enum.map(&Map.get(&1, :player_id)) |> Enum.reject(&is_nil/1)
        _other -> []
      end)
      |> Enum.concat()
      |> TwoEleven.Accounts.get_display_info()
      |> Map.new(fn info = %{id: id} -> {id, info} end)

    Map.new(presences, fn {key, value} ->
      updated_value =
        Map.update(value, :metas, %{}, fn metas ->
          Enum.map(metas, fn
            info = %{player_id: player_id} -> Map.put(info, :player, player_info[player_id])
            key_value -> key_value
          end)
        end)

      {key, updated_value}
    end)
  end
end
