defmodule ProxyTest do
  use ExUnit.Case
  import Maxwell.Middleware.TestHelper

  alias Maxwell.Conn
  test "Base Middleware Proxy" do
    conn =
      request(Maxwell.Middleware.Proxy,
        %Conn{opts: []},
        [host: "127.0.0.1", port: "100"])
    assert conn.opts == [host: "127.0.0.1", port: "100"]
  end

  test "Merge Middleware proxy" do
    conn = request(Maxwell.Middleware.Proxy,
      %Conn{opts: [host: "127.0.0.2", port: 102]},
      [host: "127.0.0.1", port: 101, user: "zhongwen", passwd: "123456"])
    assert true == Keyword.equal?(conn.opts, [host: "127.0.0.2", port: 102, user: "zhongwen", passwd: "123456"])
  end

  test "Add wrong Middleware proxy options" do
    assert_raise ArgumentError, "proxy options key only accpect [:host, :port, :user, :passwd] but got: [wrong_opts: \"wrong\"]", fn ->
      defmodule TAtom1 do
        use Maxwell.Builder, [:get]
        middleware Maxwell.Middleware.Proxy, [wrong_opts: "wrong"]
      end
      raise "ok"
    end
  end

  test "Add right Middleware proxy options" do
    assert_raise RuntimeError, "ok", fn ->
      defmodule TAtom2 do
        use Maxwell.Builder, [:get]
        middleware Maxwell.Middleware.Proxy, [host: "127.0.0.1", port: 100, user: "foo", passwd: "123"]
      end
      raise "ok"
    end
  end

end

