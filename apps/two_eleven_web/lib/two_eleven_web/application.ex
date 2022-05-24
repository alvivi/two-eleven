defmodule TwoElevenWeb.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TwoElevenWeb.Telemetry,
      TwoElevenWeb.Endpoint,
      TwoElevenWeb.Presence
    ]

    opts = [strategy: :one_for_one, name: TwoElevenWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    TwoElevenWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
