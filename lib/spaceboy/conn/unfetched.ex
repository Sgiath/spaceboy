defmodule Spaceboy.Conn.Unfetched do
  @moduledoc false
  @moduledoc authors: ["Sgiath <sgiath@sgiath.dev>"]

  use TypedStruct

  typedstruct do
    @typedoc """
    A struct used as default on unfetched fields.

    The `:aspect` key of the struct specifies what field is still unfetched.
    """

    field :aspect, :query_params | :path_params | :params
  end
end
