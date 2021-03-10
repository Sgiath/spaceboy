import Config

config :example, Example.Server,
  host: "localhost",
  port: 1965,
  certfile: "priv/ssl/cert.pem",
  keyfile: "priv/ssl/key.pem"
