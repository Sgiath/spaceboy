defmodule SpaceboyTest.Conn do
  use ExUnit.Case

  alias Spaceboy.Conn
  alias Spaceboy.Header

  doctest Spaceboy.Conn

  describe "before send" do
    test "register" do
      conn = Conn.register_before_send(%Conn{}, & &1)

      assert length(conn.before_send) == 1
    end

    test "execute" do
      conn =
        %Conn{}
        |> Conn.register_before_send(&Conn.assign(&1, :test1, :test1))
        |> Conn.register_before_send(&Conn.assign(&1, :test2, :test2))
        |> Conn.execute_before_send()

      assert conn.assigns[:test1] == :test1
      assert conn.assigns[:test2] == :test2
    end

    test "execute correct order" do
      conn =
        %Conn{}
        |> Conn.register_before_send(&Conn.assign(&1, :test, :test1))
        |> Conn.register_before_send(&Conn.assign(&1, :test, :test2))
        |> Conn.execute_before_send()

      assert conn.assigns[:test] == :test2
    end
  end

  describe "add assigns" do
    test "one key" do
      conn = Conn.assign(%Conn{}, :test, :test)

      assert conn.assigns[:test] == :test
    end

    test "merge keys" do
      conn = Conn.merge_assigns(%Conn{}, test1: :test1, test2: :test2)

      assert conn.assigns[:test1] == :test1
      assert conn.assigns[:test2] == :test2
    end
  end

  describe "add response" do
    test "just header" do
      header = Header.not_found()
      conn = Conn.resp(%Conn{}, header)

      assert conn.header == header
      assert conn.body == nil
      assert conn.state == :set
    end

    test "add header with body" do
      header = Header.success()
      body = "Example body"
      conn = Conn.resp(%Conn{}, header, body)

      assert conn.header == header
      assert conn.body == body
      assert conn.state == :set
    end

    test "add header != 20 with body" do
      header = Header.not_found()
      body = "Example body"

      assert_raise Spaceboy.OutOfSpecError, fn ->
        Conn.resp(%Conn{}, header, body)
      end
    end
  end

  describe "query params" do
    test "fetch" do
      conn = Conn.fetch_query_params(%Conn{query_string: "test1=test1&test2=test2"})

      assert conn.query_params["test1"] == "test1"
      assert conn.query_params["test2"] == "test2"
      assert conn.params["test1"] == "test1"
      assert conn.params["test2"] == "test2"
    end

    test "simple value" do
      conn = Conn.fetch_query_params(%Conn{query_string: "test"})

      assert conn.query_params["test"] == ""
      assert conn.params["test"] == ""
    end
  end
end
