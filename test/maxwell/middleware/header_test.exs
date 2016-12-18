defmodule HeaderTest do
  use ExUnit.Case
  import Maxwell.Middleware.TestHelper

  alias Maxwell.Conn
  test "Base Middleware Headers" do
    conn =
      request(Maxwell.Middleware.Headers,
        %Conn{req_headers: %{}},
        %{"content-type" => {"Content-Type", "text/plain"}})
    assert conn.req_headers == %{"content-type" => {"Content-Type", "text/plain"}}
  end

  test "Replace Middleware Headers" do
    conn = request(Maxwell.Middleware.Headers,
      %Conn{req_headers: %{"content-type" => {"Content-Type", "application/json"}}},
      %{"content-type" => {"Content-Type", "text/plain"}})
    assert conn.req_headers == %{"content-type" => {"Content-Type", "application/json"}}
  end

  test "header key is not string" do
    assert_raise ArgumentError, "Headers_map key only accpect string but got: %{key: \"value\"}", fn ->
      defmodule TAtom111 do
        use Maxwell.Builder, [:get, :post]
        middleware Maxwell.Middleware.Headers, %{:key => "value"}
      end
      raise "ok"
    end
  end

end

