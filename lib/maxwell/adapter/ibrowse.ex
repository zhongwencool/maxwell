if Code.ensure_loaded?(:ibrowse) do
  defmodule Maxwell.Adapter.Ibrowse do
    @moduledoc  """
    [`ibrowse`](https://github.com/cmullaparthi/ibrowse) adapter
    """
    use Maxwell.Adapter

    def send_direct(conn) do
      %Conn{url: url, req_headers: req_headers,
            query_string: query_string, path: path,
            method: method, opts: opts, req_body: req_body} = conn
      url = Util.url_serialize(url, path, query_string, :char_list)
      req_headers = Util.header_serialize(req_headers)
      result = :ibrowse.send_req(url, req_headers, method, req_body || "", opts)
      format_response(result, conn)
    end

    def send_file(conn) do
      %Conn{url: url, query_string: query_string, path: path,
            method: method, opts: opts, req_body: {:file, filepath}} = conn
      url = Util.url_serialize(url, path, query_string, :char_list)
      chunked = Util.chunked?(conn)
      opts =
        case chunked do
          true -> Keyword.put(opts, :transfer_encoding, :chunked)
          false -> opts
        end
      req_headers =
        chunked
        |> Util.file_header_transform(conn)
        |> Util.header_serialize
      req_body = {&Util.stream_iterate/1, filepath}
      result = :ibrowse.send_req(url, req_headers, method, req_body, opts)
      format_response(result, conn)
    end

    def send_stream(conn) do
      %Conn{url: url, req_headers: req_headers,
            query_string: query_string, path: path,
            method: method, opts: opts, req_body: req_body} = conn
      url = Util.url_serialize(url, path, query_string, :char_list)
      req_headers = Util.header_serialize(req_headers)
      req_body = {&Util.stream_iterate/1, req_body}
      result = :ibrowse.send_req(url, req_headers, method, req_body, opts)
      format_response(result, conn)
    end

    defp format_response({:ok, status, headers, body}, conn) do
      {status, _} = status |> to_string |> Integer.parse
      headers = Enum.reduce(headers, %{}, fn {k, v}, acc ->
        Map.put(acc, String.downcase(to_string(k)), to_string(v))
      end)
      %{conn | status:        status,
               resp_headers:  headers,
               resp_body:     body,
               state:         :sent,
               req_body:      nil}
    end
    defp format_response({:error, {:conn_failed, {:error, :econnrefused}}}, conn) do
      {:error, :econnrefused, %{conn | state: :error}}
    end
    defp format_response({:error, {:conn_failed, {:error, reason}}}, conn) do
      {:error, reason, %{conn | state: :error}}
    end
    defp format_response({:error, reason}, conn) do
      {:error, reason, %{conn | state: :error}}
    end
  end
end

