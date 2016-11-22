defmodule Maxwell.Middleware.DecodeRels do
@moduledoc  """
  Decode reponse's body's rels
  ```ex
  # Client.ex
  use Maxwell.Builder ~(get)a
  @middleware Maxwell.Middleware.DecodeRels
  ```
  """

  use Maxwell.Middleware
  def call(env, run, _) do
    env = run.(env)
    link = env.headers['Link'] || env.headers["Link"]

    if link do
      rels =
      link
      |> to_string
      |> String.split(",")
      |> Enum.map(&String.strip/1)
      |> Enum.reduce(%{}, fn (e, acc) ->
           case Regex.named_captures(~r/(?<value>(.+)); rel=(?<key>(.+))/, e) do
             nil -> acc;
             result -> Map.put(acc, result["key"], result["value"])
           end
         end)

      env
      |> Map.put(:rels, rels)
    else
      env
    end
  end

end
