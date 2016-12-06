defmodule OptsTest do
  use ExUnit.Case
  import Maxwell.TestHelper

  alias Maxwell.Conn
  test "Base Middleware Opts" do
    conn =
      request(Maxwell.Middleware.Opts,
        %Conn{opts: []},
        [timeout: 1000])
    assert conn.opts == [timeout: 1000]
  end

  test "Merge Middleware Opts" do
    conn = request(Maxwell.Middleware.Opts,
      %Conn{opts: [timeout: 1000]},
      [timeout: 2000])
    assert conn.opts == [timeout: 1000]
  end

  test "Add Middleware Opts" do
    conn = request(Maxwell.Middleware.Opts,
      %Conn{opts: [timeout: 1000]},
      [timeout: 2000, stream_to: :pid])
    assert Keyword.get(conn.opts, :timeout) == 1000
    assert Keyword.get(conn.opts, :stream_to, :pid)
  end

end

