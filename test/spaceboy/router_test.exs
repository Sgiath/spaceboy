defmodule SpaceboyTest.Router do
  use ExUnit.Case

  alias Spaceboy.Router

  doctest Spaceboy.Router

  describe "split/1" do
    test "standard" do
      assert ["foo", "bar"] == Router.split("/foo/bar")
      assert [":id", "*"] == Router.split("/:id/*")
      assert ["foo", "*_bar"] == Router.split("/foo//*_bar")
    end
  end

  describe "convert/2" do
    test "standard" do
      assert ["foo", "bar"] == Router.convert(["foo", "bar"])
      assert ["foo", {:_bar, [], nil}] == Router.convert(["foo", ":bar"])
      assert ["foo", {:_bar, [], nil}, "baz"] == Router.convert(["foo", ":bar", "baz"])
      assert [{:|, [], ["foo", {:_bar, [], nil}]}] == Router.convert(["foo", "*bar"])

      assert ["foo", {:|, [], ["bar", {:_baz, [], nil}]}] ==
               Router.convert(["foo", "bar", "*baz"])

      assert ["foo", {:_bar, [], nil}, {:|, [], ["foobar", {:_baz, [], nil}]}] ==
               Router.convert(["foo", ":bar", "foobar", "*baz"])
    end

    test "exeptions" do
      assert_raise RuntimeError, fn -> Router.convert(["*foo", "bar"]) end
    end
  end
end
