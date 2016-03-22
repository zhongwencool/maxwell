defmodule JsonTest do
  use ExUnit.Case

  defmodule Client do
    use Maxwell.Builder

    middleware Maxwell.Middleware.EncodeJson
    middleware Maxwell.Middleware.DecodeJson

    adapter fn (env) ->
      case env.url do
        "/decode" ->
          {:ok,
            %{env| status: 200, headers: %{'Content-Type' => 'application/json'}, body: "{\"value\": 123}"}}
        "/encode" ->
          {:ok,
            %{env| status: 200, headers: %{'Content-Type' => 'application/json'}, body: env.body |> String.replace("foo", "baz")}}
        "/empty" ->
          {:ok,
            %{env| status: 200, headers: %{'Content-Type' => 'application/json'}, body: nil}}
        "/invalid-content-type" ->
          {:ok,
            %{env| status: 200, headers: %{'Content-Type' => 'text/plain'}, body: "hello"}}
      end
    end
  end

  test "decode JSON body" do
    assert Client.get!(url: "/decode").body == %{"value" => 123}
  end

  test "do not decode empty body" do
    assert Client.get!(url: "/empty").body == nil
  end

  test "decode only if Content-Type is application/json" do
    assert Client.get!(url: "/invalid-content-type").body == "hello"
  end

  test "encode body as JSON" do
    assert Client.post!(url: "/encode", body: %{"foo" => "bar"}).body == %{"baz" => "bar"}
  end
end
