defmodule HeaderTest do
  use ExUnit.Case
  import Maxwell.MiddlewareTestHelper

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

end

