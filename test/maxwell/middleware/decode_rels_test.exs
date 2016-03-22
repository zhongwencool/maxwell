defmodule RelsTest do
  use ExUnit.Case
  import Maxwell.TestHelper

  test "Header Without Link Middleware Rels" do
    env =
      call(Maxwell.Middleware.DecodeRels,
        %{headers: %{}},
        [])
    assert env == %{headers: %{}}
  end

  test "Header With Link Middleware Rels" do
    env =
      call(Maxwell.Middleware.DecodeRels,
        %{headers: %{'Link' => "<http://localhost/users?page=1>; rel=test1, <http://localhost/users?page=2>; rel=test2, <http://localhost/users?page=3>; rel=test3"}},
        [])
    assert Map.get(env.rels, "test1") == "<http://localhost/users?page=1>"
    assert Map.get(env.rels, "test2") == "<http://localhost/users?page=2>"
    assert Map.get(env.rels, "test3") == "<http://localhost/users?page=3>"
  end

end
