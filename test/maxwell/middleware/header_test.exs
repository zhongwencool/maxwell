defmodule HeaderTest do
  use ExUnit.Case
  import Maxwell.Middleware.TestHelper

  alias Maxwell.Conn
  test "sets default request headers" do
    conn =
      request(Maxwell.Middleware.Headers, Conn.new(), %{"content-type" => "text/plain"})
    assert conn.req_headers == %{"content-type" => "text/plain"}
  end

  test "overrides request headers" do
    conn = request(Maxwell.Middleware.Headers, %Conn{req_headers: %{"content-type" => "application/json"}}, %{"content-type" => "text/plain"})
    assert conn.req_headers == %{"content-type" => "application/json"}
  end

  test "raises an error if header key is not a string" do
    assert_raise ArgumentError, "Header keys must be strings, but got: %{key: \"value\"}", fn ->
      defmodule TAtom111 do
        use Maxwell.Builder, [:get, :post]
        middleware Maxwell.Middleware.Headers, %{:key => "value"}
      end
      raise "ok"
    end
  end
end

