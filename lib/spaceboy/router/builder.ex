defmodule Spaceboy.Router.Builder do
  @moduledoc false

  @doc false
  def convert(segments, acc \\ [], params \\ [])

  def convert([":" <> segment | segments], acc, params) do
    acc = [{String.to_atom(segment), [], nil} | acc]

    convert(segments, acc, [param(segment) | params])
  end

  def convert(["*" <> segment | []], acc, params) do
    {glob(String.to_atom(segment), acc), build_params([param(segment) | params])}
  end

  def convert(["*" | []], acc, params), do: {glob(:_, acc), build_params(params)}

  def convert(["*" <> _segment | segments], _acc, _params) do
    raise "Glob pattern must be the last one. Got after: #{inspect(segments)}"
  end

  def convert(["*" | segments], _acc, _params) do
    raise "Glob pattern must be the last one. Got after: #{inspect(segments)}"
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
  defp param(segment) do
    {segment, {String.to_atom(segment), [], nil}}
  end

  # Params map AST
  defp build_params(p) do
    {:%{}, [], p}
  end
end
