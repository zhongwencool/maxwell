defmodule Maxwell.Middleware.EncodeJson do
@moduledoc  """
  Encode request's body to json when request's body is not nil

  It will auto add `%{'Content-Type': 'application/json'}` to request's headers

  Default json_lib is Poison
  ```ex
  # Client.ex
  use Maxwell.Builder ~(get)a
  @middleware Maxwell.Middleware.EncodeJson
  # or
  @middleware Maxwell.Middleware.EncodeJson, [content_type: "application/json", encode_func: &other_json_lib.encode/1]
  ```
  """
  use Maxwell.Middleware
  def call(env, run, opts) do
    encode_fun = opts[:encode_func] || &Poison.encode/1
    content_type = opts[:content_type] || "application/json"
    case env.body do
      nil ->
        run.(env)
      body when is_tuple(body) ->
        run.(env)
      _ ->
        {:ok, body} = encode_fun.(env.body)
        env = %{env | body: body}
        headers = %{'Content-Type': content_type}
        Maxwell.Middleware.Headers.call(env, run, headers)
    end
  end

end
