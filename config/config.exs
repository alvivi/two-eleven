import Config

config :esbuild,
  version: "0.14.39",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/two_eleven_web/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :tailwind,
  version: "3.0.24",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../apps/two_eleven_web/assets", __DIR__)
  ]

config :two_eleven_web, TwoElevenWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: TwoElevenWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: TwoEleven.PubSub,
  live_view: [signing_salt: "P6CSIWBJ"]

config :two_eleven_web, generators: [context_app: :two_eleven]

import_config "#{config_env()}.exs"
