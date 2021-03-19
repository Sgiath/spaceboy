import Config

# Server configuration
config :example, Example.Server,
  host: "localhost",
  port: 1965,
  certfile: "priv/ssl/cert.pem",
  keyfile: "priv/ssl/key.pem"

# Gemini MIME type
config :mime, :types, %{
  "text/gemini" => ["gmi", "gemini"]
}
