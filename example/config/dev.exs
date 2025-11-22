import Config

# Logger
# No metadata, time or empty row
config :logger, :console, format: "[$level] $message\n"

# Server configuration
config :example, Example.Server,
  adapter: Spaceboy.Adapter.ThousandIsland,
  port: 1965,
  allowed_hosts: ["localhost", "127.0.0.1"],
  certfile: "priv/ssl/cert.pem",
  keyfile: "priv/ssl/key.pem"
