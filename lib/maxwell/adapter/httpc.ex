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

  def send_file(conn) do
    %Conn{url: url, query_string: query_string, path: path,
          method: method, opts: opts, req_body: {:file, filepath}} = conn
    url = Util.url_serialize(url, path, query_string, :char_list)
    chunked = Util.chunked?(conn)
    req_headers = Util.file_header_transform(chunked, conn)
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
    chunked = Util.chunked?(conn)
    req_body =
      case chunked do
        true -> {:chunkify, &Util.stream_iterate/1, req_body}
        false -> {&Util.stream_iterate/1, req_body}
      end
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
    headers = Enum.map(headers, fn {key, value} -> {to_charlist(key), to_charlist(value)} end)
    case content_type do
      nil  -> {nil, headers}
      type -> {to_charlist(type), headers}
    end
  end

  defp opts_serialize(opts) do
    Keyword.split(opts, @http_options)
  end

  defp format_response({:ok, {status_line, headers, body}}, conn) do
    {_http_version, status, _reason_phrase} = status_line
    headers = for {key, value} <- headers, into: %{} do
      {String.downcase(to_string(key)), to_string(value)}
    end
    %{conn | status:        status,
             resp_headers:  headers,
             resp_body:     body,
             state:         :sent,
             req_body:      nil}
  end
  ## todo {:ok, request_id}

  # normalize :econnrefused for the Retry/Fuse middleware
  defp format_response({:error, {:failed_connect, info} = err}, conn) do
    conn = %{conn | state: :error}
    case List.keyfind(info, :inet, 0) do
      {:inet, _, :econnrefused} ->
        {:error, :econnrefused, %{conn | state: :error}}
      {:inet, _, reason} ->
        {:error, reason, %{conn | state: :error}}
      _ ->
        {:error, err, %{conn | state: :error}}
    end
  end
  defp format_response({:error, reason}, conn) do
    {:error, reason, %{conn | state: :error}}
  end
end

