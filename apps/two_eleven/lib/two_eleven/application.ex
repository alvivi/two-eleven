defmodule TwoEleven.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: TwoEleven.PubSub},
      {Registry, keys: :unique, name: TwoEleven.Arenas.Registry},
      {DynamicSupervisor,
       strategy: :one_for_one, restart: :transient, name: TwoEleven.Arenas.Supervisor}
    ]

    TwoEleven.Accounts.init()
    TwoEleven.Arenas.init()

    Supervisor.start_link(children, strategy: :one_for_one, name: TwoEleven.Supervisor)
  end
end
