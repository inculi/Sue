use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :desu_web, DesuWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "7cE/y3SoUvtWz0USNemOWQtEhg7GfCABeqWu4U5q+O9ZOJLuzeT/V6nxbwqdgumR",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
