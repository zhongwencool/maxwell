defmodule BaseUrlTest do
  use ExUnit.Case
  import Maxwell.MiddlewareTestHelper
  alias Maxwell.Conn
  test "Base Middleware.BaseUrl" do
    env = request(Maxwell.Middleware.BaseUrl, %Conn{url: "/path"}, "http://example.com")
    assert env.url == "http://example.com"
  end
  test "Replace http Middleware.BaseUrl" do
    env = request(Maxwell.Middleware.BaseUrl, %{url: "http://see_me.com/path"}, "http://can_not_seen.com/")
    assert env.url == "http://see_me.com/path"
  end

end

