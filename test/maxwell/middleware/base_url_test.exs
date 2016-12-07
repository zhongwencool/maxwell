defmodule BaseUrlTest do
  use ExUnit.Case
  import Maxwell.MiddlewareTestHelper
  alias Maxwell.Conn
  test "Base Middleware.BaseUrl" do
    conn = request(Maxwell.Middleware.BaseUrl, %Conn{url: "/path"}, "http://example.com")
    assert conn.url == "http://example.com"
  end
  test "Replace http Middleware.BaseUrl" do
    conn = request(Maxwell.Middleware.BaseUrl, %{url: "http://see_me.com/path"}, "http://can_not_seen.com/")
    assert conn.url == "http://see_me.com/path"
  end

end

