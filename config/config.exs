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
  render_errors: [view: DesuWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: DesuWeb.PubSub,
  live_view: [signing_salt: "bYkiLu0D"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.12.18",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/desu_web/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
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

mnesia_dir = "mnesia/#{config_env()}/#{node()}"
if not File.exists?(mnesia_dir), do: File.mkdir_p!(mnesia_dir)

config :mnesia,
  dir: String.to_charlist(mnesia_dir)

config(:sue,
  platforms: [:imessage],
  chat_db_path: Path.join(System.user_home(), "Library/Messages/chat.db")
)

import_config "config.secret.exs"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
