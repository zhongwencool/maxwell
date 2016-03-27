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
  @middleware Maxwell.Middleware.EncodeJson &other_json_lib.encode/1
  ```
  """
  def call(env, run, encode_fun) do
    unless is_function(encode_fun), do: encode_fun = &Poison.encode/1
    case env.body do
      nil ->
        run.(env)
      {:multipart, _} ->
        run.(env)
      _ ->
        {:ok, body} = encode_fun.(env.body)
        env = %{env | body: body}
        headers = %{'Content-Type': 'application/json'}
        Maxwell.Middleware.Headers.call(env, run, headers)
    end
  end

end
