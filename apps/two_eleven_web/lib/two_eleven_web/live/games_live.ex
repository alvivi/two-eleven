defmodule TwoElevenWeb.GamesLive do
  @moduledoc false

  use TwoElevenWeb, :live_view

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @spec apply_action(Socket.t(), atom(), map()) :: Socket.t()
  def apply_action(socket, :index, _params), do: socket
end
