defmodule SpaceboyTest.Specification do
  use ExUnit.Case, async: true

  alias Spaceboy.Specification

  doctest Spaceboy.Specification

  describe "valid URLs" do
    test "nothing at localhost" do
      {:ok, uri} = Specification.check("gemini://localhost\r\n")

      assert uri.scheme == "gemini"
      assert uri.host == "localhost"
      assert uri.path == nil
    end

    test "index at localhost" do
      {:ok, uri} = Specification.check("gemini://localhost/\r\n")

      assert uri.scheme == "gemini"
      assert uri.host == "localhost"
      assert uri.path == "/"
    end

    test "path at localhost" do
      {:ok, uri} = Specification.check("gemini://localhost/here/is/my/path\r\n")

      assert uri.scheme == "gemini"
      assert uri.host == "localhost"
      assert uri.path == "/here/is/my/path"
    end

    test "default port at localhost" do
      opts = [port: 1965]
      {:ok, uri} = Specification.check("gemini://localhost/\r\n", opts)

      assert uri.scheme == "gemini"
      assert uri.host == "localhost"
      assert uri.path == "/"
    end

    test "non-default port at localhost" do
      opts = [port: 1966]
      {:ok, uri} = Specification.check("gemini://localhost:1966/\r\n", opts)

      assert uri.scheme == "gemini"
      assert uri.host == "localhost"
      assert uri.path == "/"
    end

    test "allowed hosts" do
      opts = [allowed_hosts: ["example.com"]]
      {:ok, uri} = Specification.check("gemini://example.com/\r\n", opts)

      assert uri.scheme == "gemini"
      assert uri.host == "example.com"
      assert uri.path == "/"
    end
  end

  describe "invalid URLs" do
    test "missing CRLF" do
      {:error, message} = Specification.check("gemini://localhost/")

      assert message == "Missing CRLF sequence"
    end

    test "multiple lines" do
      {:error, message} = Specification.check("gemini://localhost/\r\nsecond line\r\n")

      assert message == "Multiple lines received"
    end

    test "too much data" do
      data = String.duplicate("a", 1025 - 19)
      {:error, message} = Specification.check("gemini://localhost/#{data}\r\n")

      assert message == "Too much data"
    end

    test "https scheme" do
      {:error, status, message} = Specification.check("https://localhost/\r\n")

      assert status == 53
      assert message == "Scheme is not gemini"
    end

    test "gopher scheme" do
      {:error, status, message} = Specification.check("gopher://localhost/\r\n")

      assert status == 53
      assert message == "Scheme is not gemini"
    end

    test "invalid scheme" do
      {:error, status, message} = Specification.check("fsdgf://localhost/\r\n")

      assert status == 53
      assert message == "Scheme is not gemini"
    end

    test "user info not allowed" do
      {:error, message} = Specification.check("gemini://user:password@localhost/\r\n")

      assert message == "URI cannot contain user info"
    end

    test "not matching port" do
      opts = [port: 1965]
      {:error, status, message} = Specification.check("gemini://localhost:1966/\r\n", opts)

      assert status == 53
      assert message == "Incorrect port number"
    end

    test "wrong default port" do
      opts = [port: 1966]
      {:error, status, message} = Specification.check("gemini://localhost/\r\n", opts)

      assert status == 53
      assert message == "Incorrect port number"
    end

    test "not allowed host" do
      opts = [allowed_hosts: ["localhost"]]
      {:error, status, message} = Specification.check("gemini://example.com/\r\n", opts)

      assert status == 53
      assert message == "Host example.com is not allowed"
    end
  end
end
