import Config

# Logger
# No metadata, time or empty row
config :logger, :console, format: "[$level] $message\n"

# Server configuration
config :example, Example.Server,
  port: 1965,
  allowed_hosts: ["localhost"],
  certfile: "priv/ssl/cert.pem",
  keyfile: "priv/ssl/key.pem"
