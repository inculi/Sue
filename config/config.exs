import Config

config :sue,
  chat_db_path: Path.join(System.user_home(), "Library/Messages/chat.db")

config :tesla, adapter: Tesla.Adapter.Mint

config :logger,
  level: :info

import_config "config.secret.exs"
