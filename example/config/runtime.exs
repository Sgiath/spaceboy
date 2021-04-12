import Config

# Server configuration
config :example, Example.Server,
  bind: "0.0.0.0",
  port: 1965,
  allowed_hosts: [],
  certfile: Application.app_dir(:example, "priv/ssl/cert.pem"),
  keyfile: Application.app_dir(:example, "priv/ssl/key.pem")
