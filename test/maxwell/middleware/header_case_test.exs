defmodule HeaderCaseTest do
  use ExUnit.Case, async: true

  import Maxwell.Middleware.TestHelper
  alias Maxwell.Conn

  test "lower case" do
    conn = %Conn{req_headers: %{"Content-Type" => "application/json"}}
    conn = request(Maxwell.Middleware.HeaderCase, conn, :lower)
    assert conn.req_headers == %{"content-type" => "application/json"}
  end

  test "upper case" do
    conn = %Conn{req_headers: %{"Content-Type" => "application/json"}}
    conn = request(Maxwell.Middleware.HeaderCase, conn, :upper)
    assert conn.req_headers == %{"CONTENT-TYPE" => "application/json"}
  end

  test "title case" do
    conn = %Conn{req_headers: %{"content-type" => "application/json"}}
    conn = request(Maxwell.Middleware.HeaderCase, conn, :title)
    assert conn.req_headers == %{"Content-Type" => "application/json"}

    conn = %Conn{req_headers: %{"CONTENT-TYPE" => "application/json"}}
    conn = request(Maxwell.Middleware.HeaderCase, conn, :title)
    assert conn.req_headers == %{"Content-Type" => "application/json"}

    conn = %Conn{req_headers: %{"Content-Type" => "application/json"}}
    conn = request(Maxwell.Middleware.HeaderCase, conn, :title)
    assert conn.req_headers == %{"Content-Type" => "application/json"}
  end
end
