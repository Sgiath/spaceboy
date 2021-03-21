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
  host: "localhost",
  port: 1965,
  certfile: "priv/ssl/cert.pem",
  keyfile: "priv/ssl/key.pem"

# Load env specific config
import_config "#{Mix.env()}.exs"
