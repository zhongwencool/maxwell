if Code.ensure_loaded?(:hackney) do
  defmodule Maxwell.Adapter.Hackney do
    @moduledoc  """
    [`hackney`](https://github.com/benoitc/hackney) adapter
    """
    use Maxwell.Adapter

    def send_direct(conn) do
      %Conn{url: url, req_headers: req_headers,
            path: path,method: method, query_string: query_string,
            opts: opts, req_body: req_body} = conn
      url = Util.url_serialize(url, path, query_string)
      req_headers = Util.header_serialize(req_headers)
      result = :hackney.request(method, url, req_headers, req_body || "", opts)
      format_response(result, conn)
    end

    def send_file(conn), do: send_direct(conn)

    def send_stream(conn) do
      %Conn{url: url, req_headers: req_headers,
            path: path,method: method, query_string: query_string,
            opts: opts, req_body: req_body} = conn
      url = Util.url_serialize(url, path, query_string)
      req_headers = Util.header_serialize(req_headers)
      with {:ok, ref} <- :hackney.request(method, url, req_headers, :stream, opts) do
        for data <- req_body, do: :ok = :hackney.send_body(ref, data)
        ref |> :hackney.start_response |> format_response(conn)
      else
        error -> format_response(error, conn)
      end
    end

    defp format_response({:ok, status, headers, body}, conn) when is_binary(body) do
      headers = Enum.reduce(headers, %{}, fn {k, v}, acc ->
        Map.put(acc, String.downcase(to_string(k)), to_string(v))
      end)
      %{conn | status:        status,
               resp_headers:  headers,
               req_body:      nil,
               state:         :sent,
               resp_body:     body}
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

