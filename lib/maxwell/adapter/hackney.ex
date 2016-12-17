if Code.ensure_loaded?(:hackney) do
  defmodule Maxwell.Adapter.Hackney do
    use Maxwell.Adapter
    @moduledoc  """
    [`hackney`](https://github.com/benoitc/hackney) adapter
    """

    @doc """
    * `conn` - `%Maxwell.Conn{}`

    Returns `{:ok, %Maxwell.Conn{}}` or `{:error, reason_term, %Maxwell.Conn{}}`.
    """
    def send_direct(conn) do
      %Maxwell.Conn{url: url, req_headers: req_headers,
                    path: path,method: method, query_string: query_string,
                    opts: opts, req_body: req_body} = conn
      url = url_serialize(url, path, query_string)
      req_headers = header_serialize(req_headers)
      result = :hackney.request(method, url, req_headers, req_body || "", opts)
      format_response(result, conn)
    end

    def send_multipart(conn), do: send_direct(conn)

    def send_file(conn), do: send_direct(conn)

    def send_stream(conn) do
      %Maxwell.Conn{url: url, req_headers: req_headers,
                    path: path,method: method, query_string: query_string,
                    opts: opts, req_body: req_body} = conn
      url = url_serialize(url, path, query_string)
      req_headers = header_serialize(req_headers)
      with {:ok, ref} <- :hackney.request(method, url, req_headers, :stream, opts) do
        for data <- req_body, do: :ok = :hackney.send_body(ref, data)
        ref |> :hackney.start_response |> format_response(conn)
      else
        error -> format_response(error, conn)
      end
    end


    defp url_serialize(url, path, query_string) do
      url |> Maxwell.Conn.append_query_string(path, query_string) |> to_char_list
    end
    defp header_serialize(headers) do
      headers |> Enum.map(fn({_, origin_header}) -> origin_header end)
    end

    defp format_response({:ok, status, headers, body}, conn) when is_binary(body) do
      headers = headers
      |> Enum.reduce(%{}, fn({key, value}, acc) ->
        key = key |> to_string |> String.downcase
        Map.put(acc, key, {key, to_string(value)})
      end)
      {:ok, %{conn | status: status,
              resp_headers:  headers,
              req_body:      nil,
              state:         :sent,
              resp_body:     body}}
    end
    defp format_response({:ok, status, headers, body}, conn) do
      case :hackney.body(body) do
        {:ok, body} -> format_response({:ok, status, headers, body}, conn)
        {:error, _reason} = error -> format_response(error, conn)
      end
    end
    defp format_response({:ok, status, headers}, conn) do
      format_response({:ok, status, headers, ""}, conn)
    end

    defp format_response({:error, reason}, conn) do
      {:error, reason, %{conn | state: :error}}
    end

  end

end

