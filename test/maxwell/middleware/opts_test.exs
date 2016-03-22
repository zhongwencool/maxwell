defmodule OptsTest do
  use ExUnit.Case
  import Maxwell.TestHelper

  test "Base.Middleware.Opts" do
    env =
      call(Maxwell.Middleware.Opts,
        %{opts: []},
        [timeout: 1000])
    assert env.opts == [timeout: 1000]
  end

  test "Merge.Middleware.Opts" do
    env = call(Maxwell.Middleware.Opts,
      %{opts: [timeout: 1000]},
      [timeout: 2000])
    assert env.opts == [timeout: 1000]
  end

  test "add.Middleware.Opts" do
    env = call(Maxwell.Middleware.Opts,
      %{opts: [timeout: 1000]},
      [timeout: 2000, repond_to: :pid])
    assert Keyword.get(env.opts, :timeout) == 1000
    assert Keyword.get(env.opts, :repond_to, :pid)
  end

end
