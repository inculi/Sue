# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of Mix.Config.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
use Mix.Config

config :sue_web,
  generators: [context_app: :sue]

# Configures the endpoint
config :sue_web, SueWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "qEhmB5qxvx4dxoOvnvi8dXFyy/SX0YnC8O6MkmUHVx9Er/KZzzjoRXD+ZgxJ/O9V",
  render_errors: [view: SueWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Sue.PubSub,
  live_view: [signing_salt: "dJ8+9K2d"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  level: :debug,
  metadata: [:request_id]

Logger.put_module_level(Tesla.Middleware.Logger, :info)
Logger.put_module_level(Mint, :info)

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

mnesia_dir = "mnesia/#{Mix.env()}/#{node()}"
if not File.exists?(mnesia_dir), do: File.mkdir_p!(mnesia_dir)

config :mnesia,
  dir: String.to_charlist(mnesia_dir)

config(:sue,
  platforms: [:imessage, :telegram],
  chat_db_path: Path.join(System.user_home(), "Library/Messages/chat.db")
)

config :tesla, adapter: Tesla.Adapter.Mint

import_config "config.secret.exs"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
