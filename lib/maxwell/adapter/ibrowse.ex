if Code.ensure_loaded?(:ibrowse) do
  defmodule Maxwell.Adapter.Ibrowse do
    use Maxwell.Adapter
    @moduledoc  """
    [`ibrowse`](https://github.com/cmullaparthi/ibrowse) adapter
    """

    @doc """
    * `conn` - `%Maxwell.Conn{}`

    Returns `{:ok, %Maxwell.Conn{}}` or `{:error, reason_term, %Maxwell.Conn{}}`.
    """
    def send_direct(conn) do
      %Maxwell.Conn{url: url, req_headers: req_headers,
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
      %Maxwell.Conn{url: url, req_headers: req_headers,
                    query_string: query_string, path: path,
                    method: method, opts: opts, req_body: {:multipart, req_body}} = conn
      url = url_serialize(url, path, query_string)
      req_headers = header_serialize(req_headers)
      {req_headers, req_body} = multipart_encode(req_headers, req_body)
      result = :ibrowse.send_req(url, req_headers, method, req_body, opts)
      format_response(result, conn)
    end

    def send_file(conn) do
      %Maxwell.Conn{url: url, req_headers: req_headers,
                    query_string: query_string, path: path,
                    method: method, opts: opts, req_body: {:file, req_body}} = conn
      url = url_serialize(url, path, query_string)
      req_headers = header_serialize(req_headers)
      {req_headers, req_body} = file_encode(req_headers, req_body)
      result = :ibrowse.send_req(url, req_headers, method, req_body, opts)
      format_response(result, conn)
    end

    def send_stream(conn) do
      %Maxwell.Conn{url: url, req_headers: req_headers,
                    query_string: query_string, path: path,
                    method: method, opts: opts, req_body: req_body} = conn
      url = url_serialize(url, path, query_string)
      req_headers = header_serialize(req_headers)
      req_body = stream_encode(req_body)
      result = :ibrowse.send_req(url, req_headers, method, req_body, opts)
      format_response(result, conn)
    end

    defp url_serialize(url, path, query_string) do
      url |> Maxwell.Conn.append_query_string(path, query_string) |> to_char_list
    end
    defp header_serialize(header) do
      header |> Map.to_list
    end

    defp format_response({:ok, status, headers, body}, conn) do
      {status, _} = status |> to_string |> Integer.parse
      {:ok, %{conn |status:   status,
              resp_headers:  headers |> :maps.from_list,
              resp_body:     body,
              state:         :sent,
              req_body:      nil}
      }
    end
    defp format_response({:error, reason}, conn) do
      {:error, reason, %{conn | state: :error}}
    end

    def multipart_encode(headers, multiparts) do
      boundary = Maxwell.Multipart.new_boundary
      body =
        {fn(:start) ->
                  {body, _size} = Maxwell.Multipart.encode_form(boundary, multiparts)
                  {:ok, body, :end}
           (:end) -> :eof
        end, :start}
      len = Maxwell.Multipart.len_mp_stream(boundary, multiparts)
      headers = [{'Content-Type', "multipart/form-data; boundary=#{boundary}"}, {'Content-Length', len}|headers]
      {headers, body}
    end

    def file_encode(headers, filepath) do
      body =
        {fn(:start) ->
            with {:ok, body} <- File.read(filepath) do
            {:ok, body, :end}
            end
          (:end) -> :eof
        end, :start}
      size = :filelib.file_size(filepath)
      content_type = :mimerl.filename(filepath)
      headers = [{'Content-Type', content_type}, {'Content-Length', size}|headers]
      {headers, body}
    end

    def stream_encode(body) do
      {fn(:start) ->
        {:ok, body |> Enum.to_list |> IO.iodata_to_binary, :end}
        (:end) -> :eof
      end, :start}
    end

  end

end

