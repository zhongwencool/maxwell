defmodule HeaderTest do
  use ExUnit.Case
  import Maxwell.TestHelper

  test "Base.Middleware.Headers" do
    env =
      call(Maxwell.Middleware.Headers,
        %{headers: %{}},
        %{'Content-Type' => 'text/plain'})
    assert env.headers == %{'Content-Type' => 'text/plain'}
  end

  test "Merge.Middleware.Headers" do
    env = call(Maxwell.Middleware.Headers,
      %{headers: %{'Content-Type' => "application/json"}},
      %{'Content-Type' => 'text/plain'})
    assert env.headers == %{'Content-Type' => "application/json"}
  end

end
