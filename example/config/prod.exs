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
