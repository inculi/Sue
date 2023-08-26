# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of Mix.Config.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

config :desu_web,
  generators: [context_app: false]

# Configures the endpoint
config :desu_web, DesuWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: DesuWeb.ErrorHTML, json: DesuWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Desu.PubSub,
  live_view: [signing_salt: "YEBB28eM"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/desu_web/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.2.7",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../apps/desu_web/assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  level: :debug,
  metadata: [:request_id]

config :tesla,
  log_level: :warn,
  adapter: Tesla.Adapter.Mint

config :tesla, Tesla.Middleware.Logger,
  log_level: :warn,
  debug: false

Logger.put_module_level(Tesla, :warn)
Logger.put_module_level(Tesla.Middleware.Logger, :warn)
Logger.put_module_level(ExGram.Adapter.Tesla, :warn)
Logger.put_module_level(Tesla, :warn)

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :sue,
  platforms: [:debug],
  chat_db_path: Path.join(System.user_home(), "Library/Messages/chat.db")

config :subaru,
  dbname: "subaru_#{config_env()}"

import_config "config.secret.exs"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
