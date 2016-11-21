defmodule Maxwell.Middleware.Json do
  @moduledoc  """
  Encode request's body to json when request's body is not nil
  Decode response's body to json when reponse's header contain `{'Content-Type', "application/json"}` and body is binary
  or Reponse's body is list

  It will auto add `%{'Content-Type': 'application/json'}` to request's headers

  Default json_lib is Poison
  ```ex
  # Client.ex
  use Maxwell.Builder ~(get)a
  @middleware Maxwell.Middleware.Json
  # or
  @middleware Maxwell.Middleware.Json, [content_type: "application/json", encode_func: &other_json_lib.encode/1]
  ```
  """
  use Maxwell.Middleware

  def request(env, opts) do
    Maxwell.Middleware.EncodeJson.request(env, opts)
  end
  def response(env, opts) do
    Maxwell.Middleware.DecodeJson.response(env, opts)
  end

end

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

  def request(env, opts) do
    encode_fun = opts[:encode_func] || &Poison.encode/1
    content_type = opts[:content_type] || "application/json"
    case env.body do
      nil ->
        env
      body when is_tuple(body) ->
        env
      _ ->
        {:ok, body} = encode_fun.(env.body)
        env = %{env | body: body}
        headers = %{'Content-Type': content_type}
        ## todo
        Maxwell.Middleware.Headers.request(env, headers)
    end
  end

end

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
  @middleware Maxwell.Middleware.DecodeJson, [valid_types: "text/javascript", decode_func: &other_json_lib.decode/1]
  ```
  """
use Maxwell.Middleware

  def response(response, opts) do
    decode_fun = opts[:decode_func] || &Poison.decode/1
    valid_content_types = opts[:valid_types] || []
    with {:ok, result = %Maxwell{}} <- response do

      content_type = result.headers['Content-Type'] || result.headers["Content-Type"]
      || result.headers['content-type'] || result.headers["content-type"]||''
      content_type = content_type |> to_string

      case is_json_content(content_type, result.body, valid_content_types) do
        true ->
          case decode_fun.(result.body) do
            {:ok, body}  -> {:ok, %{result | body: body}}
            {:error, reason} -> {:error, {:decode_json_error, reason}}
          end
        _ ->
          {:ok, result}
        end
    end

  end

  def is_json_content(content_type, body, valid_types) do
    valid_types = ["application/json", "text/javascript"| valid_types]
    is_valid_type = Enum.find(valid_types, fn(x) -> String.starts_with?(content_type, x) end)
    is_valid_type && (is_binary(body) || is_list(body))
  end

end
