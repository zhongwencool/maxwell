defmodule Maxwell.Middleware.Headers do
  @moduledoc  """
  Add fixed headers to request's headers

  ## Examples

        # Client.ex
        use Maxwell.Builder ~(get)a
        middleware Maxwell.Middleware.Headers, %{'User-Agent' => "zhongwencool"}

        def request do
          # headers is merge to %{'User-Agent' => "zhongwencool", 'username' => "zhongwencool"}
          new()
          |> put_req_header(%{'username' => "zhongwencool"})
          |> get!
        end

  """
  use Maxwell.Middleware
  alias Maxwell.Conn

  def init(headers) do
    check_headers(headers)
    Conn.new()
    |> Conn.put_req_headers(headers)
    |> Map.get(:req_headers)
  end

  def request(%Conn{} = conn, req_headers) do
    Conn.put_req_headers(conn, req_headers)
  end

  defp check_headers(headers) do
    case Enum.all?(headers, fn {key, _value} -> is_binary(key) end) do
      true  -> :ok
      false -> raise(ArgumentError, "Header keys must be strings, but got: #{inspect headers}");
    end
  end
end

