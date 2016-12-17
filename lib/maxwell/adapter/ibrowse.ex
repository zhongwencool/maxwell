if Code.ensure_loaded?(:ibrowse) do
  defmodule Maxwell.Adapter.Ibrowse do
    @moduledoc  """
    [`ibrowse`](https://github.com/cmullaparthi/ibrowse) adapter
    """

    @chunk_size 4*1024*1024
    use Maxwell.Adapter


    @doc """
    * `conn` - `%Maxwell.Conn{}`

    Returns `{:ok, %Maxwell.Conn{}}` or `{:error, reason_term, %Maxwell.Conn{}}`.
    """
    def send_direct(conn) do
      %Conn{url: url, req_headers: req_headers,
            query_string: query_string, path: path,
            method: method, opts: opts, req_body: req_body} = conn
      url = url_serialize(url, path, query_string)
      req_headers = header_serialize(req_headers)
      result = :ibrowse.send_req(url, req_headers, method, req_body || "", opts)
      format_response(result, conn)
    end

    @doc """
    * `conn` - `%Maxwell.Conn{}`

    Returns `{:ok, %Maxwell.Conn{}}` or `{:error, reason_term, %Maxwell.Conn{}}`.
    """
    def send_multipart(conn) do
      %Conn{url: url,query_string: query_string, path: path,
            method: method, opts: opts, req_body: {:multipart, multiparts}} = conn
      url = url_serialize(url, path, query_string)
      {req_headers, req_body} = multipart_encode(conn, multiparts)
      req_headers = header_serialize(req_headers)
      result = :ibrowse.send_req(url, req_headers, method, req_body, opts)
      format_response(result, conn)
    end

    def send_file(conn) do
      %Conn{url: url, req_headers: req_headers,
            query_string: query_string, path: path,
            method: method, opts: opts, req_body: {:file, filepath}} = conn
      url = url_serialize(url, path, query_string)
      opts = Keyword.put(opts, :transfer_encoding, :chunked) # it auto add "transfer_encodeing: chunked" header
      req_headers =
        req_headers
        |> Map.has_key?("content-type")
        |> case do
             true ->
               req_headers |> header_serialize
             false ->
               content_type = :mimerl.filename(filepath)
               conn
               |> Conn.put_req_header("content-type", content_type)
               |> Map.get(:req_headers)
               |> header_serialize
           end
      req_body = {&stream_iterate/1, filepath}
      result = :ibrowse.send_req(url, req_headers, method, req_body, opts)
      format_response(result, conn)
    end

    def send_stream(conn) do
      %Conn{url: url, req_headers: req_headers,
            query_string: query_string, path: path,
            method: method, opts: opts, req_body: req_body} = conn
      url = url_serialize(url, path, query_string)
      req_headers = header_serialize(req_headers)
      req_body = {&stream_iterate/1, req_body}
      opts = Keyword.put(opts, :transfer_encoding, :chunked) # it auto add "transfer_encodeing: chunked" header
      result = :ibrowse.send_req(url, req_headers, method, req_body, opts)
      format_response(result, conn)
    end

    defp url_serialize(url, path, query_string) do
      url |> Conn.append_query_string(path, query_string) |> to_char_list
    end
    defp header_serialize(headers) do
      headers |> Enum.map(&elem(&1, 1))
    end

    defp format_response({:ok, status, headers, body}, conn) do
      {status, _} = status |> to_string |> Integer.parse
      headers = for {key, value}<- headers, into: %{} do
        down_key = key |> to_string |> String.downcase
        {down_key, {key, to_string(value)}}
      end
      {:ok, %{conn |status:   status,
              resp_headers:  headers,
              resp_body:     body,
              state:         :sent,
              req_body:      nil}
      }
    end
    defp format_response({:error, reason}, conn) do
      {:error, reason, %{conn | state: :error}}
    end

    defp multipart_encode(conn, multiparts) do
      boundary = Maxwell.Multipart.new_boundary
      body = {&multipart_body/1, {:start, boundary, multiparts}}

      len = Maxwell.Multipart.len_mp_stream(boundary, multiparts)
      headers = conn
      |> Conn.put_req_header("content-type", "multipart/form-data; boundary=#{boundary}")
      |> Conn.put_req_header("content-length", len)
      |> Map.get(:req_headers)

      {headers, body}
    end

    defp multipart_body({:start, boundary, multiparts}) do
      {body, _size} = Maxwell.Multipart.encode_form(boundary, multiparts)
      {:ok, body, :end}
    end
    defp multipart_body(:end), do: :eof

    defp stream_iterate(filepath) when is_binary(filepath) do
      filepath
      |> File.stream!([], @chunk_size)
      |> stream_iterate
    end
    defp stream_iterate(next_stream_fun)when is_function(next_stream_fun, 1) do
      case next_stream_fun.({:cont, nil}) do
        {:suspended, elem, next_stream_fun} -> {:ok, elem, next_stream_fun}
        {:halted, _} -> :eof
        {:done, _} -> :eof
      end
    end
    defp stream_iterate(stream) do
		  case Enumerable.reduce(stream, {:cont, nil}, fn(elem, nil) -> {:suspend, elem} end) do
        {:suspended, elem, next_stream} -> {:ok, elem, next_stream}
			  {:done, _} -> :eof
        {:halted, _} -> :eof
		  end
    end

  end

end

