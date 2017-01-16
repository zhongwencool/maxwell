defmodule HeaderCaseTest do
  use ExUnit.Case, async: true

  import Maxwell.Middleware.TestHelper
  alias Maxwell.Conn

  test "lower case" do
    opts = Maxwell.Middleware.HeaderCase.init(:lower)
    conn = %Conn{req_headers: %{"Content-Type" => "application/json"}}
    conn = request(Maxwell.Middleware.HeaderCase, conn, opts)
    assert conn.req_headers == %{"content-type" => "application/json"}
  end

  test "upper case" do
    opts = Maxwell.Middleware.HeaderCase.init(:upper)
    conn = %Conn{req_headers: %{"Content-Type" => "application/json"}}
    conn = request(Maxwell.Middleware.HeaderCase, conn, opts)
    assert conn.req_headers == %{"CONTENT-TYPE" => "application/json"}
  end

  test "title case" do
    opts = Maxwell.Middleware.HeaderCase.init(:title)
    conn = %Conn{req_headers: %{"content-type" => "application/json"}}
    conn = request(Maxwell.Middleware.HeaderCase, conn, opts)
    assert conn.req_headers == %{"Content-Type" => "application/json"}

    conn = %Conn{req_headers: %{"CONTENT-TYPE" => "application/json"}}
    conn = request(Maxwell.Middleware.HeaderCase, conn, opts)
    assert conn.req_headers == %{"Content-Type" => "application/json"}

    conn = %Conn{req_headers: %{"Content-Type" => "application/json"}}
    conn = request(Maxwell.Middleware.HeaderCase, conn, opts)
    assert conn.req_headers == %{"Content-Type" => "application/json"}
  end

  test "invalid casing style raises ArgumentError" do
    assert_raise ArgumentError, fn -> Maxwell.Middleware.HeaderCase.init(:foo) end
  end
end
