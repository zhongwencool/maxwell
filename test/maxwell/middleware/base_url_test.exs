defmodule BaseUrlTest do
  use ExUnit.Case 
  import Maxwell.Middleware.TestHelper 
  alias Maxwell.Conn 

  test "simple base url" do
    opts = Maxwell.Middleware.BaseUrl.init("http://example.com")
    conn = request(Maxwell.Middleware.BaseUrl, %Conn{path: "/path"}, opts)
    assert conn.url == "http://example.com"
    assert conn.path == "/path"
  end

  test "base url and base path" do
    opts = Maxwell.Middleware.BaseUrl.init("http://example.com/api/v1")
    conn = request(Maxwell.Middleware.BaseUrl, %Conn{path: "/path"}, opts)
    assert conn.url == "http://example.com"
    assert conn.path == "/api/v1/path"
  end

  test "base url, base path, and default query" do
    opts = Maxwell.Middleware.BaseUrl.init("http://example.com/api/v1?apiKey=foo")
    conn = request(Maxwell.Middleware.BaseUrl, %Conn{path: "/path"}, opts)
    assert conn.url == "http://example.com"
    assert conn.path == "/api/v1/path"
    assert conn.query_string == %{"apiKey" => "foo"}
  end

  test "default query is merged" do
    opts = Maxwell.Middleware.BaseUrl.init("http://example.com/api/v1?apiKey=foo&user=me")
    conn = %Conn{path: "/path", query_string: %{"apiKey" => "bar", "other" => "thing"}}
    conn = request(Maxwell.Middleware.BaseUrl, conn, opts)
    assert conn.url == "http://example.com"
    assert conn.path == "/api/v1/path"
    assert conn.query_string == %{"apiKey" => "bar", "other" => "thing", "user" => "me"}
  end

  test "base url can be overriden if set on connection" do
    opts = Maxwell.Middleware.BaseUrl.init("http://notseen.com")
    conn = request(Maxwell.Middleware.BaseUrl, %Conn{url: "http://seen/path"}, opts)
    assert conn.url == "http://seen/path"
  end

  test "invalid base url will raise an ArgumentError" do
    assert_raise ArgumentError, fn -> Maxwell.Middleware.BaseUrl.init("/foo") end
  end
end

