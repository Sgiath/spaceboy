defmodule Spaceboy.Router.Builder do
  @moduledoc false

  @spec convert(segments :: [String.t()], acc :: [Macro.t()], params :: [Macro.t()]) :: Macro.t()
  def convert(segments, acc \\ [], params \\ [])

  def convert([":" <> segment | segments], acc, params) do
    segment = String.to_atom(segment)

    convert(segments, [{segment, [], nil} | acc], param(params, segment))
  end

  def convert(["*" <> segment | []], acc, params) do
    segment = String.to_atom(segment)

    {glob(segment, acc), params |> param(segment) |> build_params()}
  end

  def convert(["*" | []], acc, params), do: {glob(:_, acc), build_params(params)}

  def convert(["*" <> _segment | segments], _acc, _params) do
    raise ArgumentError, "Glob pattern must be the last one. Got after: #{inspect(segments)}"
  end

  def convert(["*" | segments], _acc, _params) do
    raise ArgumentError, "Glob pattern must be the last one. Got after: #{inspect(segments)}"
  end

  def convert([segment | segments], acc, params) do
    convert(segments, [segment | acc], params)
  end

  def convert([], acc, params) do
    {Enum.reverse(acc), build_params(params)}
  end

  # Build glob pattern AST
  defp glob(segment, [ha | acc]) do
    Enum.reverse([{:|, [], [ha, {segment, [], nil}]} | acc])
  end

  # One param match AST
  defp param(params, segment) do
    Keyword.put(params, segment, {segment, [], nil})
  end

  # Params map AST
  defp build_params(params) do
    {:%{}, [], params}
  end
end
