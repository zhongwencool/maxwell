defmodule MaxwellAdapterTest do
  use ExUnit.Case

  defmodule ModuleAdapter do
    def call(conn) do
      {:ok, %{conn|status: 200,
              resp_headers: %{"Content-Type" => "text/plain"},
              resp_body: "testbody",
              state: :sent}}
    end
  end

  defmodule Client do
    use Maxwell.Builder
    adapter ModuleAdapter
  end

  alias Maxwell.Conn
  test "return :status 200" do
    {:ok, result} = Client.get()
    assert Conn.get_status(result) == 200
  end

  test "return resp content-type header" do
    {:ok, conn} = Client.get()
    assert Conn.get_resp_header(conn) == %{"Content-Type" => "text/plain"}
    assert Conn.get_resp_header(conn, "Content-Type") == "text/plain"
  end

  test "return resp_body" do
    {:ok, conn} = Client.get
    assert Conn.get_resp_body(conn) == "testbody"
    assert Conn.get_resp_body(conn, &String.length/1) == 8
  end

  test "http method" do
    {:ok, conn} = Client.get
    conn1 = Client.get!
    assert Map.equal?(conn, conn1) == true
    assert conn1.method == :get
    {:ok, conn} = Client.head
    conn1 = Client.head!
    assert Map.equal?(conn, conn1) == true
    assert conn.method == :head
    {:ok, conn} = Client.post
    conn1 = Client.post!()
    assert Map.equal?(conn, conn1) == true
    assert conn.method == :post
    {:ok, conn} = Client.put
    conn1 = Client.put!
    assert Map.equal?(conn, conn1) == true
    assert conn.method == :put
    {:ok, conn} = Client.patch
    conn1 = Client.patch!
    assert Map.equal?(conn, conn1) == true
    assert conn.method == :patch
    {:ok, conn} = Client.delete
    conn1 = Client.delete!
    assert Map.equal?(conn, conn1) == true
    assert conn.method == :delete
    {:ok, conn} = Client.trace
    conn1 = Client.trace!
    assert Map.equal?(conn, conn1) == true
    assert conn.method == :trace
    {:ok, conn} = Client.options
    conn1 = Client.options!
    assert Map.equal?(conn, conn1) == true
    assert conn.method == :options
  end

  test "path + query" do
   conn =
      Conn.put_url("http://example.com")
      |> Conn.put_path("/foo")
      |> Conn.put_query_string(%{a: 1, b: "foo"})
      |> Client.get!
   assert conn.url == "http://example.com"
   assert conn.path == "/foo"
   assert conn.query_string == %{a: 1, b: "foo"}
   assert Conn.get_status(conn) == 200
  end
end

