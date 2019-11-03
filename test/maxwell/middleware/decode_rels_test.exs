defmodule RelsTest do
  use ExUnit.Case
  import Maxwell.Middleware.TestHelper
  alias Maxwell.Conn

  test "Header Without Link Middleware Rels" do
    conn = response(Maxwell.Middleware.Rels, %Conn{resp_headers: %{}}, [])
    assert conn == %Conn{resp_headers: %{}}
  end

  test "Header With Link Middleware Rels and match" do
    conn =
      response(
        Maxwell.Middleware.Rels,
        %Conn{
          resp_headers: %{
            'Link' =>
              "<http://localhost/users?page=1>; rel=test1, <http://localhost/users?page=2>; rel=test2, <http://localhost/users?page=3>; rel=test3"
          }
        },
        []
      )

    assert Map.get(conn.rels, "test1") == "<http://localhost/users?page=1>"
    assert Map.get(conn.rels, "test2") == "<http://localhost/users?page=2>"
    assert Map.get(conn.rels, "test3") == "<http://localhost/users?page=3>"
  end

  test "Header With Link Middleware Rels and don't match" do
    conn =
      response(
        Maxwell.Middleware.Rels,
        %Conn{resp_headers: %{'Link' => "lkdfjldkjfdwrongformat"}},
        []
      )

    assert conn.rels == %{}
  end
end
