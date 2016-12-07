defmodule HeaderTest do
  use ExUnit.Case
  import Maxwell.MiddlewareTestHelper

  alias Maxwell.Conn
  test "Base Middleware Headers" do
    conn =
      request(Maxwell.Middleware.Headers,
        %Conn{req_headers: %{}},
        %{"Content-Type" => "text/plain"})
    assert conn.req_headers == %{"Content-Type" => "text/plain"}
  end

  test "Replace Middleware Headers" do
    conn = request(Maxwell.Middleware.Headers,
      %{req_headers: %{"Content-Type" => "application/json"}},
      %{"Content-Type" => "text/plain"})
    assert conn.req_headers == %{"Content-Type" => "application/json"}
  end

end

