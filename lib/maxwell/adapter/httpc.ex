defmodule Maxwell.Adapter.Httpc do
  @moduledoc  """
  [`httpc`](http://erlang.org/doc/man/httpc.html) adapter
  """

  @http_options [:timeout, :connect_timeout, :ssl, :essl, :autoredirect, :proxy_auth, :version, :relaxed, :url_encode]
  use Maxwell.Adapter

  def send_direct(conn) do
    %Conn{url: url, req_headers: req_headers,
          query_string: query_string, path: path,
          method: method, opts: opts, req_body: req_body} = conn
    url = Util.url_serialize(url, path, query_string, :char_list)
    {content_type, req_headers} = header_serialize(req_headers)
    {http_opts, options} = opts_serialize(opts)
    result = request(method, url, req_headers, content_type, req_body, http_opts, options)
    format_response(result, conn)
  end

  def send_multipart(conn) do
    %Conn{url: url,query_string: query_string, path: path,
          method: method, opts: opts, req_body: {:multipart, multiparts}} = conn
    url = Util.url_serialize(url, path, query_string, :char_list)
    {req_headers, req_body} = Util.multipart_encode(conn, multiparts)
    {content_type, req_headers} = header_serialize(req_headers)
    {http_opts, options} = opts_serialize(opts)
    result = request(method, url, req_headers, content_type, req_body, http_opts, options)
    format_response(result, conn)
  end

  def send_file(conn) do
    %Conn{url: url, req_headers: req_headers,
          query_string: query_string, path: path,
          method: method, opts: opts, req_body: {:file, filepath}} = conn
    url = Util.url_serialize(url, path, query_string, :char_list)
    chunked = Util.chunked?(conn)
    req_headers = Util.file_header_serialize(chunked, conn, req_headers)
    req_body =
      case chunked do
        true -> {:chunkify, &Util.stream_iterate/1, filepath}
        false -> {&Util.stream_iterate/1, filepath}
      end
    {content_type, req_headers} = header_serialize(req_headers)
    {http_opts, options} = opts_serialize(opts)
    result = request(method, url, req_headers, content_type, req_body, http_opts, options)
    format_response(result, conn)
  end

  def send_stream(conn) do
    %Conn{url: url, req_headers: req_headers,
          query_string: query_string, path: path,
          method: method, opts: opts, req_body: req_body} = conn
    url = Util.url_serialize(url, path, query_string, :char_list)
    req_body = {:chunkify, &Util.stream_iterate/1, req_body}
    {content_type, req_headers} = header_serialize(req_headers)
    {http_opts, options} = opts_serialize(opts)
    result = request(method, url, req_headers, content_type, req_body, http_opts, options)
    format_response(result, conn)
  end

  defp request(method, url, req_headers, _content_type, nil, http_opts, options) do
    :httpc.request(method, {url, req_headers}, http_opts, options)
  end
  defp request(method, url, req_headers, content_type, req_body, http_opts, options) do
    :httpc.request(method, {url, req_headers, content_type, req_body}, http_opts, options)
  end

  defp header_serialize(headers) do
    {content_type, headers} = Map.pop(headers, "content-type")
    headers = Enum.map(headers, fn({_, {key, value}}) -> {to_char_list(key), to_char_list(value)} end)
    case content_type do
      nil -> {nil, headers}
      {_, type} -> {to_char_list(type), headers}
    end
  end

  defp opts_serialize(opts) do
    Keyword.split(opts, @http_options)
  end

  defp format_response({:ok, {status_line, headers, body}}, conn) do
    {_http_version, status, _reason_phrase} = status_line
    headers = for {key, value} <- headers, into: %{} do
      key = key |> to_string
      down_key = key |> String.downcase
      {down_key, {key, to_string(value)}}
    end
    {:ok, %{conn |status:   status,
            resp_headers:  headers,
            resp_body:     body,
            state:         :sent,
            req_body:      nil}
    }
  end
  ## todo {:ok, request_id}
  defp format_response({:error, reason}, conn) do
    {:error, reason, %{conn | state: :error}}
  end

end

