defmodule MaxwellTest do
  use ExUnit.Case

  defmodule ClientWithAdapterFun do
    use Maxwell.Builder
    adapter fn (env) ->
      {:ok, %{env | status: 201, resp_headers: [], resp_body: "function adapter", state: :sent}}
    end
  end

  defmodule ClientWithLocalAdapterFun do
    use Maxwell.Builder
    adapter :handle

    def handle(env) do
      {:ok, %{env | status: 201, resp_headers: [], resp_body: "function adapter", state: :sent}}
    end
  end

  defmodule ModuleAdapter do
    def call(env) do
      {:ok, %{env | status: 202, state: :sent}}
    end
  end

  defmodule ClientWithAdapterMod do
    use Maxwell.Builder

    adapter ModuleAdapter
  end
  alias Maxwell.Conn
  test "client with adapter as function fn(x) -> x end" do
    {:ok, conn} = ClientWithAdapterFun.get()
    assert Conn.get_status(conn) == 201
  end

  test "client with adapter as module" do
    {:ok, conn} = ClientWithAdapterMod.get()
    assert Conn.get_status(conn) == 202
  end

  test "client with local method" do
    {:ok, conn} = ClientWithLocalAdapterFun.get()
    assert Conn.get_status(conn) == 201
  end

  defmodule Client do
    use Maxwell.Builder

    adapter fn (env) ->
      {:ok, %{env|status: 200, resp_headers: %{"Content-Type" => "text/plain"}, resp_body: "body", state: :sent}}
    end
  end

  alias Maxwell.Conn

  test "return :status 200" do
    {:ok, result} = Client.get()
    assert Conn.get_status(result) == 200
  end

  test "return content type header" do
    {:ok, conn} = Client.get()
    assert Conn.get_resp_header(conn) == %{"Content-Type" => "text/plain"}
    assert Conn.get_resp_header(conn, "Content-Type") == "text/plain"
  end

  test "return 'resp_body' as body" do
    {:ok, conn} = Client.get
    assert Conn.get_resp_body(conn) == "body"
  end

  test "GET request" do
    {:ok, conn} = Client.get
    conn1 = Client.get!
    assert Map.equal?(conn, conn1) == true
    assert conn1.method == :get
  end

  test "HEAD request" do
    {:ok, conn} = Client.head
    conn1 = Client.head!
    assert Map.equal?(conn, conn1) == true
    assert conn.method == :head
  end

  test "POST request" do
    {:ok, conn} = Client.post
    conn1 = Client.post!()
    assert Map.equal?(conn, conn1) == true
    assert conn.method == :post
  end

  test "PUT request" do
    {:ok, conn} = Client.put
    conn1 = Client.put!
    assert Map.equal?(conn, conn1) == true
    assert conn.method == :put
  end

  test "PATCH request" do
    {:ok, conn} = Client.patch
    conn1 = Client.patch!
    assert Map.equal?(conn, conn1) == true
    assert conn.method == :patch
  end

  test "DELETE request" do
    {:ok, conn} = Client.delete
    conn1 = Client.delete!
    assert Map.equal?(conn, conn1) == true
    assert conn.method == :delete
  end

  test "TRACE request" do
    {:ok, conn} = Client.trace
    conn1 = Client.trace!
    assert Map.equal?(conn, conn1) == true
    assert conn.method == :trace
  end

  test "OPTIONS request" do
    {:ok, conn} = Client.options
    conn1 = Client.options!
    assert Map.equal?(conn, conn1) == true
    assert conn.method == :options
  end

  alias Maxwell.Conn
  test "path + query" do
   conn =
      Conn.put_url("/foo")
      |> Conn.put_query_string(%{a: 1, b: "foo"})
      |> Client.get!
   assert conn.url == "/foo"
   assert conn.query_string == %{a: 1, b: "foo"}
   assert Conn.get_status(conn) == 200
  end

end

defmodule MiddlewareTest do
  use ExUnit.Case

  defmodule Client do
    use Maxwell.Builder, ["get", "post"]

    middleware Maxwell.Middleware.BaseUrl, "http://example.com"
    middleware Maxwell.Middleware.Opts, [connect_timeout: 3000]
    middleware Maxwell.Middleware.Headers, %{"Content-Type" => "application/json"}
    middleware Maxwell.Middleware.Json

    adapter fn (conn) ->
      conn = %{conn| state: :sent}
      body = unless conn.req_body, do: %{}, else: Poison.decode!(conn.req_body)
      if Map.equal?(body, %{"key2" => 101, "key1" => 201}) do
        {:ok, %{conn| status: 200, resp_headers: %{"Content-Type" => "application/json"}, resp_body: "{\"key2\":101,\"key1\":201}"}}
      else
        {:ok, %{conn| status: 200, resp_headers: %{"Content-Type" => "application/json"}, resp_body: "{\"key2\":2,\"key1\":1}"}}
      end
    end
  end

  alias Maxwell.Conn

  test "make use of base url" do
    assert Client.get!().url == "http://example.com"
  end

  test "make use of options" do
    assert Client.post!().opts == [connect_timeout: 3000]
  end

  test "make use of headers" do
    headers = Client.get!|> Conn.get_resp_header
    assert headers == %{"Content-Type" => "application/json"}
  end

  test "make use of endeodejson" do
    body = %{"key2" => 101, "key1" => 201} |> Conn.put_req_body |> Client.post! |> Conn.get_resp_body
    assert true == Map.equal?(body, %{"key2" => 101, "key1" => 201})
  end

  test "make use of deodejson" do
    body = Client.post! |> Conn.get_resp_body
    assert body == %{"key2" => 2, "key1" => 1}
  end

end

