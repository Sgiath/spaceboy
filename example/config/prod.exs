import Config

# Logger
# Just want info logs in production
config :logger,
  level: :info,
  compile_time_purge_matching: [
    [level_lower_than: :info]
  ]

# Don't do empty row
config :logger, :console, format: "$time $metadata[$level] $message\n"

# Server configuration
config :example, Example.Server,
  port: 1965,
  allowed_hosts: ["example.com"],
  certfile: Application.app_dir(:example, "priv/ssl/cert.pem"),
  keyfile: Application.app_dir(:example, "priv/ssl/key.pem")
