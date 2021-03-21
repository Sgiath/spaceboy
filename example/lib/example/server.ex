defmodule Example.Server do
  use Spaceboy.Server, otp_app: :example

  middleware Spaceboy.Middleware.Logger

  middleware Spaceboy.Middleware.RequestId

  middleware Example.Router
end
