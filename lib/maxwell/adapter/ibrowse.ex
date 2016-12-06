if Code.ensure_loaded?(:ibrowse) do
  defmodule Maxwell.Adapter.Ibrowse do
    @moduledoc  """
    [ibrowse](https://github.com/cmullaparthi/ibrowse) adapter
    """

    @doc """
    * `conn` - `%Maxwell.Conn{}`

    Returns `{:ok, %Maxwell.Conn{}}` or `{:error, reason_term, %Maxwell.Conn{}}`.
    """
    def call(conn) do
      conn
      |> send_req
      |> format_response(conn)
    end

    defp send_req(%Maxwell.Conn{url: url, req_headers: req_headers,
                                query_string: query_string, path: path,
                                method: method, opts: opts, req_body: req_body}) do
      url = url |> Maxwell.Conn.append_query_string(path, query_string) |> to_char_list
      req_body = req_body || ""
      req_headers = req_headers |> Map.to_list
      :ibrowse.send_req(url, req_headers, method, req_body, opts)
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

    ## todo support multipart
    # def need_multipart_encode(headers, {:multipart, multipart}) do
    #  boundary = Maxwell.Multipart.new_boundary
    #  body =
    # {fn(true) ->
    #  {body, _size} = Maxwell.Multipart.encode(boundary, multipart)
    #  {:ok, body, false}
    #  (false) -> :eof
    # end, true}
    #  len = Maxwell.Multipart.len_mp_stream(boundary, multipart)
    #  headers = [{'Content-Type', "multipart/form-data; boundary=#{boundary}"}, {'Content-Length', len}|headers]
    #  {headers, body}
    # end
    #def need_multipart_encode(headers, body), do: {headers, body || []}

  end

end

