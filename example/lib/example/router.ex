defmodule Example.Router do
  use Spaceboy.Router

  alias Example.Controller

  route "/", Controller, :index
  route "/user", Controller, :users
  route "/user/:user_id", Controller, :user
  route "/cert", Controller, :cert
  route "/file", Controller, :file
  route "/template", Controller, :template

  static "/static", "priv/static"
end
