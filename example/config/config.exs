import Config

# Logger
# Include request ID in metadata (Spaceboy.Middleware.RequestId)
config :logger, :console, metadata: [:request_id]

# Gemini MIME type
config :mime, :types, %{
  "text/gemini" => ["gmi", "gemini"]
}

# Load env specific config
import_config "#{Mix.env()}.exs"
