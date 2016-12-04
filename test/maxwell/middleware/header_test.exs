defmodule HeaderTest do
  use ExUnit.Case
  import Maxwell.TestHelper

  alias Maxwell.Conn
  test "Base.Middleware.Headers" do
    env =
      request(Maxwell.Middleware.Headers,
        %Conn{req_headers: %{}},
        %{"Content-Type" => "text/plain"})
    assert env.req_headers == %{"Content-Type" => "text/plain"}
  end

  test "Merge.Middleware.Headers" do
    env = request(Maxwell.Middleware.Headers,
      %{req_headers: %{"Content-Type" => "application/json"}},
      %{"Content-Type" => "text/plain"})
    assert env.req_headers == %{"Content-Type" => "application/json"}
  end

end
