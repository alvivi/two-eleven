defmodule TwoElevenWeb.PageController do
  @moduledoc false

  use TwoElevenWeb, :controller

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params), do: redirect(conn, to: Routes.games_path(conn, :index))
end
