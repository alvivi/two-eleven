defmodule TwoEleven.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the PubSub system
      {Phoenix.PubSub, name: TwoEleven.PubSub}
      # Start a worker by calling: TwoEleven.Worker.start_link(arg)
      # {TwoEleven.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: TwoEleven.Supervisor)
  end
end
