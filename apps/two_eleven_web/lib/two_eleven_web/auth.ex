defmodule TwoElevenWeb.Auth do
  @moduledoc false

  alias Phoenix.LiveView.Socket
  alias Plug.Conn
  alias TwoEleven.Accounts
  alias TwoElevenWeb.Router.Helpers, as: Routes

  @invalid_player_message "Invalid player credentials. You will be signed in as new player."
  @remember_me_cookie "_two_eleven_web_remember_me"
  @remember_me_options [sign: true, same_site: "Lax"]

  @spec fetch_current_player(Conn.t(), keyword()) :: Conn.t()
  def fetch_current_player(conn, _opts) do
    {conn, player_id, player_token} = ensure_player_token(conn)

    if is_nil(player_id) or is_nil(player_token) do
      {:ok, player} = Accounts.new_player()
      remember_me = {player.id, player.token}

      conn
      |> renew_session()
      |> Conn.put_resp_cookie(@remember_me_cookie, remember_me, @remember_me_options)
      |> put_token_in_session(player.id, player.token)
      |> Conn.assign(:current_player, player)
    else
      case Accounts.fetch_player(player_id, player_token) do
        {:ok, player} ->
          Conn.assign(conn, :current_player, player)

        :error ->
          conn
          |> renew_session()
          |> Conn.delete_resp_cookie(@remember_me_cookie)
          |> Phoenix.Controller.put_flash(:error, @invalid_player_message)
          |> Phoenix.Controller.redirect(to: "/")
          |> Conn.halt()
      end
    end
  end

  @spec on_mount(atom(), map(), map(), Socket.t()) :: {:cont, Socket.t()} | :halt
  def on_mount(_name, _params, session, socket) do
    with {:ok, player_id} <- Map.fetch(session, "player_id"),
         {:ok, player_token} <- Map.fetch(session, "player_token"),
         {:ok, player} <- Accounts.fetch_player(player_id, player_token) do
      {:cont, Phoenix.LiveView.assign(socket, :player, player)}
    else
      _error ->
        target = Routes.page_path(TwoElevenWeb.Endpoint, :index)
        socket = Phoenix.LiveView.redirect(socket, to: target)

        {:halt, socket}
    end
  end

  @spec ensure_player_token(Conn.t()) :: {Conn.t(), binary() | nil, binary() | nil}
  defp ensure_player_token(conn) do
    player_id = Conn.get_session(conn, :player_id)
    player_token = Conn.get_session(conn, :player_token)

    if is_nil(player_id) or is_nil(player_token) do
      conn = Conn.fetch_cookies(conn, signed: [@remember_me_cookie])

      case conn.cookies[@remember_me_cookie] do
        {player_id, player_token} ->
          conn = put_token_in_session(conn, player_id, player_token)
          {conn, player_id, player_token}

        _no_cookie ->
          {conn, nil, nil}
      end
    else
      {conn, player_id, player_token}
    end
  end

  @spec put_token_in_session(Conn.t(), binary(), binary()) :: Conn.t()
  defp put_token_in_session(conn, player_id, player_token) do
    conn
    |> Conn.put_session(:player_id, player_id)
    |> Conn.put_session(:player_token, player_token)
    |> Conn.put_session(:live_socket_id, "player_sessions:#{player_id}")
  end

  @spec renew_session(Conn.t()) :: Conn.t()
  defp renew_session(conn) do
    conn
    |> Conn.configure_session(renew: true)
    |> Conn.clear_session()
  end
end
