defmodule ConnTest do
  use ExUnit.Case

  import Maxwell.Adapter.Util

  test "url_serialize/4" do
    assert url_serialize("http://example.com", "/foo", %{"ids" => ["1", "2"]}) == "http://example.com/foo?ids[]=1&ids[]=2"
    assert url_serialize("http://example.com", "/foo", %{"ids" => %{"foo" => "1"}}) == "http://example.com/foo?ids[foo]=1"
  end
end
