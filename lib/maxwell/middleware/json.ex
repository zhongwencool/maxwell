defmodule Maxwell.Middleware.Json do
  @moduledoc  """
  Encode request's body to json when request's body is not nil
  Decode response's body to json when reponse's header contain `{'Content-Type', "application/json"}` and body is binary
  or Reponse's body is list

  It will auto add `%{'Content-Type': 'application/json'}` to request's headers

  Default json_lib is Poison

  ## Examples

        # Client.ex
        use Maxwell.Builder ~(get)a
        middleware Maxwell.Middleware.Json

        # OR

        middleware Maxwell.Middleware.Json,
          encode_content_type: "application/json",
          encode_func: &other_json_lib.encode/1,
          decode_content_types: ["yourowntype"],
          decode_func: &other_json_lib.decode/1

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

  def request(%Maxwell.Conn{} = conn, {encode_opts, _decode_opts}) do
    Maxwell.Middleware.EncodeJson.request(conn, encode_opts)
  end
  def response(%Maxwell.Conn{} = conn, {_encode_opts, decode_opts}) do
    Maxwell.Middleware.DecodeJson.response(conn, decode_opts)
  end

  defp check_opts(opts) do
    for {key, value} <- opts do
      case key do
        :encode_func ->
          unless is_function(value, 1), do: raise(ArgumentError, "Json Middleware :encode_func only accepts function/1");
        :encode_content_type ->
          unless is_binary(value), do: raise(ArgumentError, "Json Middleware :encode_content_types only accepts string");
        :decode_func ->
          unless is_function(value, 1), do: raise(ArgumentError, "Json Middleware :decode_func only accepts function/1");
        :decode_content_types ->
          unless is_list(value), do: raise(ArgumentError, "Json Middleware :decode_content_types only accepts lists");
        _ -> raise(ArgumentError, "Json Middleware Options doesn't accept #{key}")
      end
    end
  end

end

defmodule Maxwell.Middleware.EncodeJson do
  @moduledoc  """
  Encode request's body to json when request's body is not nil

  It will auto add `%{'Content-Type': 'application/json'}` to request's headers

  Default json_lib is Poison

  ## Examples

        # Client.ex
        use Maxwell.Builder ~(get)a
        middleware Maxwell.Middleware.EncodeJson

        # OR

        middleware Maxwell.Middleware.EncodeJson,
          encode_content_type: "application/json",
          encode_func: &other_json_lib.encode/1

  """
  use Maxwell.Middleware
  alias Maxwell.Conn

  def init(opts) do
    check_opts(opts)
    encode_func = opts[:encode_func] || &Poison.encode/1
    content_type = opts[:encode_content_type] || "application/json"
    {encode_func, content_type}
  end

  def request(conn = %Conn{req_body: req_body}, _opts)when is_nil(req_body) or is_tuple(req_body) or is_atom(req_body), do: conn
  def request(conn = %Conn{req_body: %Stream{}}, _opts), do: conn
  def request(conn = %Conn{req_body: req_body}, {encode_func, content_type}) do
    {:ok, req_body} = encode_func.(req_body)
    conn
    |> Conn.put_req_body(req_body)
    |> Conn.put_req_header("content-type", content_type)
  end

  defp check_opts(opts) do
    for {key, value} <- opts do
      case key do
        :encode_func ->
          unless is_function(value, 1), do: raise(ArgumentError, "EncodeJson :encode_func only accepts function/1");
        :encode_content_type ->
          unless is_binary(value), do: raise(ArgumentError, "EncodeJson :encode_content_types only accepts string");
        _ -> raise(ArgumentError, "EncodeJson Options doesn't accept #{key} (:encode_func and :encode_content_type)")
      end
    end
  end
end

defmodule Maxwell.Middleware.DecodeJson do
  @moduledoc  """
  Decode response's body to json when

  1. The reponse headers contain a content type of `application/json` and body is binary.
  2. The response is a list

  Default json decoder is Poison

  ## Examples

        # Client.ex
        use Maxwell.Builder ~(get)a
        middleware Maxwell.Middleware.DecodeJson

        # OR

        middleware Maxwell.Middleware.DecodeJson,
          decode_content_types: ["text/javascript"],
          decode_func: &other_json_lib.decode/1

  """
  use Maxwell.Middleware

  def init(opts) do
    check_opts(opts)
    {opts[:decode_func] || &Poison.decode/1, opts[:decode_content_types] || []}
  end

  def response(%Maxwell.Conn{} = conn, {decode_fun, valid_content_types}) do
    with {:ok, content_type} <- fetch_resp_content_type(conn),
         true <- valid_content?(content_type, conn.resp_body, valid_content_types),
         {:ok, resp_body} <- decode_fun.(conn.resp_body) do
      %{conn | resp_body: resp_body}
    else
      :error -> conn
      false -> conn
      {:error, reason} -> {:error, {:decode_json_error, reason}, conn}
      {:error, reason, pos} -> {:error, {:decode_json_error, reason, pos}, conn}
    end
  end

  defp valid_content?(content_type, body, valid_types) do
    present?(body) &&
    String.starts_with?(content_type, "application/json") ||
    String.starts_with?(content_type, "text/javascript") ||
    Enum.any?(valid_types, &String.starts_with?(content_type, &1))
  end

  defp fetch_resp_content_type(conn) do
    if content_type = Maxwell.Conn.get_resp_header(conn, "content-type") do
      {:ok, content_type}
    else
      :error
    end
  end

  defp present?(""), do: false
  defp present?([]), do: false
  defp present?(term) when is_binary(term) or is_list(term), do: true
  defp present?(_), do: false

  defp check_opts(opts) do
    for {key, value} <- opts do
      case key do
        :decode_func ->
          unless is_function(value, 1), do: raise(ArgumentError, "DecodeJson :decode_func only accepts function/1");
        :decode_content_types ->
          unless is_list(value), do: raise(ArgumentError, "DecodeJson :decode_content_types only accepts lists");
        _ ->
          raise(ArgumentError, "DecodeJson Options doesn't accept #{key} (:decode_func and :decode_content_types)")
      end
    end
  end
end
