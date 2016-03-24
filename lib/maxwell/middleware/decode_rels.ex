defmodule Maxwell.Middleware.DecodeRels do
@moduledoc  """
  Decode reponse's body's rels
  ```ex
  # Client.ex
  use Maxwell.Builder ~(get)a
  @middleware Maxwell.Middleware.DecodeRels
  ```
  """
  def call(env, run, _) do
    env = run.(env)

    if env.headers['Link'] do
      rels =
      env.headers['Link']
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
