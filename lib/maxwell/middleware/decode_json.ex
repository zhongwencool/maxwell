defmodule Maxwell.Middleware.DecodeJson do
@moduledoc  """
  Decode reponse's body to json when

    1. Reponse header contain `{'Content-Type', "application/json"}` and body is binary

    2. Reponse is list

  Default json_lib is Poison
  ```ex
  # Client.ex
  use Maxwell.Builder ~(get)a
  @middleware Maxwell.Middleware.DecodeJson
  # or
  @middleware Maxwell.Middleware.DecodeJson &other_json_lib.decode/1
  ```
  """
  def call(env, run, decode_fun) do
    unless is_function(decode_fun), do: decode_fun = &Poison.decode/1
    with {:ok, result = %Maxwell{}} <- run.(env) do

      content_type = result.headers['Content-Type'] || result.headers["Content-Type"] ||''
      content_type = content_type |> to_string

      case is_json_content(content_type, result.body) do
        true ->
          case decode_fun.(to_string(result.body)) do
            {:ok, body}  -> {:ok, %{result | body: body}}
            {:error, reason} -> {:error, {:decode_json_error, reason}}
          end
        _ ->
          {:ok, result}
        end
    end

  end

  def is_json_content(content_type, body) do
    valid_types = ["application/json", "text/javascript"]
    is_valid_type = Enum.find(valid_types, fn(x) -> String.starts_with?(content_type, x) end)
    is_valid_type && (is_binary(body) || is_list(body))
  end

end
