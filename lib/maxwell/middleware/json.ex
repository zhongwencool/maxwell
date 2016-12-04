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
  @middleware Maxwell.Middleware.Json, [encode_content_type: "application/json", encode_func: &other_json_lib.encode/1,
  decode_content_types: ["yourowntype"],   decode_func: &other_json_lib.decode/1]
  ```
  """
  use Maxwell.Middleware
  def init(opts) do
    check_opts(opts)
    encode_func = opts[:encode_func] || &Poison.encode/1
    decode_content_type = opts[:encode_content_type] || "application/json"
    decode_func = opts[:decode_func] || &Poison.decode/1
    decode_content_types =  opts[:decode_content_types] || []
    {{encode_func, decode_content_type},
     {decode_func, decode_content_types}}
  end

  def request(conn, {encode_opts, _decode_opts}) do
    Maxwell.Middleware.EncodeJson.request(conn, encode_opts)
  end
  def response(conn, {_encode_opts, decode_opts}) do
    Maxwell.Middleware.DecodeJson.response(conn, decode_opts)
  end

  defp check_opts(opts) do
    for {key, value} <- opts do
      case key do
        :encode_func ->
          unless is_function(value, 1), do: raise(ArgumentError, "Json Middleware :encode_func only accpect function/1");
        :encode_content_type ->
          unless is_binary(value), do: raise(ArgumentError, "Json Middleware :encode_content_types only accpect string");
        :decode_func ->
          unless is_function(value, 1), do: raise(ArgumentError, "Json Middleware :decode_func only accpect function/1");
        :decode_content_types ->
          unless is_list(value), do: raise(ArgumentError, "Json Middleware :decode_content_types only accpect lists");
        _ -> raise(ArgumentError, "Json Middleware Options don't accpect #{key}")
      end
    end
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
  @middleware Maxwell.Middleware.EncodeJson, [encode_content_type: "application/json", encode_func: &other_json_lib.encode/1]
  ```
  """
  use Maxwell.Middleware

  def init(opts) do
    check_opts(opts)
    encode_func = opts[:encode_func] || &Poison.encode/1
    content_type = opts[:encode_content_type] || "application/json"
    {encode_func, content_type}
  end

  def request(conn, {encode_func, content_type}) do
    case conn.req_body do
      nil -> conn
      req_body when is_tuple(req_body) -> conn
      _ ->
        {:ok, req_body} = encode_func.(conn.req_body)
        conn = %{conn | req_body: req_body}
        headers = %{"content-type" => content_type}
        Maxwell.Middleware.Headers.request(conn, headers)
    end
  end

  defp check_opts(opts) do
    for {key, value} <- opts do
      case key do
        :encode_func ->
          unless is_function(value, 1), do: raise(ArgumentError, "EncodeJson :encode_func only accpect function/1");
        :encode_content_type ->
          unless is_binary(value), do: raise(ArgumentError, "EncodeJson :encode_content_types only accpect string");
        _ -> raise(ArgumentError, "EncodeJson Options don't accpect #{key} (:encode_func and :encode_content_type)")
      end
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
  @middleware Maxwell.Middleware.DecodeJson, [decode_content_types: ["text/javascript"], decode_func: &other_json_lib.decode/1]
  ```
  """
  use Maxwell.Middleware
  def init(opts) do
    check_opts(opts)
    {opts[:decode_func] || &Poison.decode/1, opts[:decode_content_types] || []}
  end

  def response(response, {decode_fun, valid_content_types}) do
    with {:ok, conn = %Maxwell.Conn{}} <- response do
      headers = conn.resp_headers
      content_type = headers['Content-Type'] || headers["Content-Type"]
      || headers['content-type'] || headers["content-type"] || ''
      content_type = content_type |> to_string
      case is_json_content(content_type, conn.resp_body, valid_content_types) do
        true ->
          case decode_fun.(conn.resp_body) do
            {:ok, resp_body}  -> {:ok, %{conn | resp_body: resp_body}}
            {:error, reason} -> {:error, {:decode_json_error, reason}, conn}
          end
        _ ->
          {:ok, conn}
      end
    end

  end

  defp is_json_content(content_type, body, valid_types) do
    valid_types = ["application/json", "text/javascript"| valid_types]
    is_valid_type = Enum.find(valid_types, fn(x) -> String.starts_with?(content_type, x) end)
    is_valid_type && (is_binary(body) || is_list(body))
  end

  defp check_opts(opts) do
    for {key, value} <- opts do
      case key do
        :decode_func ->
          unless is_function(value, 1), do: raise(ArgumentError, "DecodeJson :decode_func only accpect function/1");
        :decode_content_types ->
          unless is_list(value), do: raise(ArgumentError, "DecodeJson :decode_content_types only accpect lists");
        _ ->
          raise(ArgumentError, "DecodeJson Options don't accpect #{key} (:decode_func and :decode_content_types)")
      end
    end
  end

end
