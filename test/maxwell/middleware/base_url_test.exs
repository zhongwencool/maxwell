defmodule BaseUrlTest do
  use ExUnit.Case
  import Maxwell.TestHelper

  test "Base Middleware.BaseUrl" do
    env = request(Maxwell.Middleware.BaseUrl, %{url: "/path"}, "http://example.com")
    assert env.url == "http://example.com/path"
  end
  test "Merge http Middleware.BaseUrl" do
    env = request(Maxwell.Middleware.BaseUrl, %{url: "http://see_me.com/path"}, "http://can_not_seen.com/")
    assert env.url == "http://see_me.com/path"
  end

end
