defmodule SpaceboyTest.Controller do
  use ExUnit.Case

  alias Spaceboy.Conn
  alias Spaceboy.Controller

  doctest Spaceboy.Controller

  test "gemini response" do
    body = """
    # Header

    test
    """

    conn = Controller.gemini(%Conn{}, body)

    assert conn.header.code == 20
    assert conn.header.meta =~ "text/gemini"
    assert conn.body == body
  end

  test "json response" do
    body = %{test: "test"}
    conn = Controller.json(%Conn{}, body)

    assert conn.header.code == 20
    assert conn.header.meta =~ "application/json"
    assert conn.body == Jason.encode!(body)
  end

  test "input response" do
    prompt = "Search term"
    conn = Controller.input(%Conn{}, prompt)

    assert conn.header.code == 10
    assert conn.header.meta == prompt
    assert conn.body == nil
  end

  test "redirect response" do
    path = "/redirect/here/please"
    conn = Controller.redirect(%Conn{}, path)

    assert conn.header.code == 30
    assert conn.header.meta == path
    assert conn.body == nil
  end

  test "not_found response" do
    conn = Controller.not_found(%Conn{})

    assert conn.header.code == 51
    assert conn.header.meta == "Page not found"
    assert conn.body == nil
  end

  test "auth_required response" do
    conn = Controller.auth_required(%Conn{})

    assert conn.header.code == 60
    assert conn.header.meta == "Certificate is missing"
    assert conn.body == nil
  end
end
