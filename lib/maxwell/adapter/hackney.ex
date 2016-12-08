if Code.ensure_loaded?(:hackney) do
  defmodule Maxwell.Adapter.Hackney do
    @behaviour Maxwell.Adapter
    @moduledoc  """
    [`hackney`](https://github.com/benoitc/hackney) adapter
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
                                path: path,method: method, query_string: query_string,
                                opts: opts, req_body: req_body}) do
      req_headers = req_headers |> Map.to_list
      req_body = req_body || ""
      url = url |> Maxwell.Conn.append_query_string(path, query_string)
      :hackney.request(method, url, req_headers, req_body, opts)
    end

    defp format_response({:ok, status, headers, body}, conn) when is_binary(body) do
      {:ok, %{conn | status:   status,
              resp_headers:  headers|> :maps.from_list,
              req_body: nil,
              state: :sent,
              resp_body:     body}}
    end
    defp format_response({:ok, status, headers, body}, conn) do
      with {:ok, body} <- :hackney.body(body) do
        {:ok,
         %{conn |status:   status,
           resp_headers:  headers|> :maps.from_list,
           req_body: nil,
           state: :sent,
           resp_body:     body}}
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

