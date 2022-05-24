import Config

config :logger, level: :info

# NOTE: For developing purposes (overridden at runtime)
default_secret_key_base =
  :crypto.strong_rand_bytes(64) |> Base.encode64(padding: false) |> binary_part(0, 64)

config :two_eleven_web, TwoElevenWeb.Endpoint, secret_key_base: default_secret_key_base
