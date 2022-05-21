import Config

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :plug_init_mode, :runtime

config :phoenix, :stacktrace_depth, 20

config :two_eleven_web, TwoElevenWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "g0Tl+8YMiYrdWomvFqSY5oRDONwTa/rxlZwqyde4tSFbLI9FLIpz5I0My0CFuAUu",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
  ]

config :two_eleven_web, TwoElevenWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/two_eleven_web/(live|views)/.*(ex)$",
      ~r"lib/two_eleven_web/templates/.*(eex)$"
    ]
  ]
