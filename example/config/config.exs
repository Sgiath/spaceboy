import Config

# Logger
# Include request ID in metadata (Spaceboy.Middleware.RequestId)
config :logger, :console, metadata: [:request_id]

# Gemini MIME type
config :mime, :types, %{
  "text/gemini" => ["gmi", "gemini"]
}

# Server configuration
config :example, Example.Server,
  bind: "0.0.0.0",
  port: 1965,
  allowed_hosts: [],
  certfile: "priv/ssl/cert.pem",
  keyfile: "priv/ssl/key.pem"

# Load env specific config
import_config "#{Mix.env()}.exs"
