defmodule MiddlewareTest do
  use ExUnit.Case

  defmodule Adapter do
    def call(conn) do
      conn = %{conn| state: :sent}
      body = unless conn.req_body, do: %{}, else: Poison.decode!(conn.req_body)
      if Map.equal?(body, %{"key2" => 101, "key1" => 201}) do
        %{conn| status: 200, resp_headers: %{"content-type" => "application/json"},
                resp_body: "{\"key2\":101,\"key1\":201}"}
      else
        %{conn| status: 200, resp_headers: %{"content-type" => "application/json"},
                resp_body: "{\"key2\":2,\"key1\":1}"}
      end
    end
  end

  defmodule Client do
    use Maxwell.Builder, ["get", "post"]

    middleware Maxwell.Middleware.BaseUrl, "http://example.com"
    middleware Maxwell.Middleware.Opts, [connect_timeout: 3000]
    middleware Maxwell.Middleware.Headers, %{"Content-Type" => "application/json"}
    middleware Maxwell.Middleware.Json

    adapter Adapter
  end

  import Maxwell.Conn

  test "make use of base url" do
    assert Client.get!().url == "http://example.com"
  end

  test "make use of options" do
    assert Client.post!().opts == [connect_timeout: 3000]
  end

  test "make use of headers" do
    assert Client.get!|> get_resp_headers() == %{"content-type" => "application/json"}
    assert Client.get!|> get_resp_header("Content-Type") == "application/json"
  end

  test "make use of endeodejson" do
    body = new() |> put_req_body(%{"key2" => 101, "key1" => 201}) |> Client.post! |> get_resp_body
    assert true == Map.equal?(body, %{"key2" => 101, "key1" => 201})
  end

  test "make use of deodejson" do
    assert Client.post! |> get_resp_body == %{"key2" => 2, "key1" => 1}
  end
end

