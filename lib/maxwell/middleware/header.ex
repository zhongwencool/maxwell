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
  alias Maxwell.Conn

  def init(headers) do
    check_headers(headers)
    Conn.put_req_header(%Conn{}, headers) |> Map.get(:req_headers)
  end

  def request(conn, req_headers) do
    %{conn| req_headers: Map.merge(req_headers, conn.req_headers)}
  end

  defp check_headers(headers) do
    case Enum.all?(headers, fn({key, _value}) -> is_binary(key) end) do
      true -> :ok
      false -> raise(ArgumentError, "Headers_map key only accpect string but got: #{inspect headers}");
    end
  end
end

