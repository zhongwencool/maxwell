defmodule Maxwell.Middleware.Rels do
  @moduledoc  """
  Decode reponse's body's rels.

  ## Examples

         # Client.ex
         use Maxwell.Builder ~(get)a
         middleware Maxwell.Middleware.Rels

  """
  use Maxwell.Middleware

  def response(%Maxwell.Conn{} = conn, _opts) do
    link = conn.resp_headers['Link'] || conn.resp_headers["Link"]
    if link do
      rels =
      link
      |> to_string
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.reduce(%{}, fn (e, acc) ->
           case Regex.named_captures(~r/(?<value>(.+)); rel=(?<key>(.+))/, e) do
             nil -> acc;
             result -> Map.put(acc, result["key"], result["value"])
           end
         end)

      Map.put(conn, :rels, rels)
    else
      conn
    end
  end
end

