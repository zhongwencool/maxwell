defmodule LoggerTest do
  use ExUnit.Case
  import Maxwell.TestHelper

  test "Middleware.Logger request" do
    env = request(Maxwell.Middleware.Logger, %Maxwell.Conn{url: "/path"}, [])
    assert env == %Maxwell.Conn{url: "/path"}
  end

  test "Middleware.Logger response" do
    {:ok, env} = response(Maxwell.Middleware.Logger, {:ok, %Maxwell.Conn{url: "/path"}}, [])
    assert env == %Maxwell.Conn{url: "/path"}
  end

end

