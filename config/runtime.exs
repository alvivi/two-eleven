import Config

host = System.get_env("HOST")
port = System.get_env("PORT") || "8080" |> String.to_integer()
secret_key_base = System.get_env("SECRET_KEY_BASE")

if is_nil(host) do
  config :two_eleven_web, TwoElevenWeb.Endpoint, server: true, http: [port: port]
else
  if is_nil(secret_key_base) do
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """
  end

  config :two_eleven_web, TwoElevenWeb.Endpoint,
    server: true,
    http: [
      port: port,
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    secret_key_base: secret_key_base,
    url: [host: host]
end
