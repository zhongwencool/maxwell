defmodule Maxwell.Middleware.Headers do
  @moduledoc  """
  Add fixed headers to request's headers

  ### Examples

        # Client.ex
        use Maxwell.Builder ~(get)a
        @middleware Maxwell.Middleware.Headers %{'User-Agent' => "zhongwencool"}

        def request do
        # headers is merge to %{'User-Agent' => "zhongwencool", 'username' => "zhongwencool"}
          %{'username' => "zhongwencool"} |> put_req_header |> get!
        end

  """

  use Maxwell.Middleware

  def request(conn, req_headers) do
    headers = Map.merge(req_headers, conn.req_headers)
    %{conn | req_headers: headers}
  end
end

