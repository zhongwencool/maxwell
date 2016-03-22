defmodule Maxwell.Until do

  def append_query_string(url, query) do
    if query != %{} do
      query_string = URI.encode_query(query)
      if url |> String.contains?("?") do
        url <> "&" <> query_string
      else
        url <> "?" <> query_string
      end
    else
      url
    end

  end

  def adjust_method_format(methods, default_methods) do
    case methods do
      [] ->
        default_methods
      {:sigil_w, _, [{:<<>>, _, [methods_str]}, _]} ->
        methods_str |> String.split(" ") |> Enum.map(&String.to_atom/1)
      [method| _] when is_atom(method) ->
        methods
      [method|_] when is_binary(method) ->
        methods |> Enum.map(&String.to_atom/1)
      _ ->
        raise "http methods format must be [:get] or [\"get\"] or ~w(get) or ~w(get)a #{methods}"
    end
  end

  def is_allow_methods(methods, allow_methods) do
   Enum.each(methods,
     fn(method) ->
        unless method in allow_methods do
        raise "http methods don't support #{method}"
     end
   end)
  end

end
