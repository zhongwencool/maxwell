defmodule JsonTest do
  use ExUnit.Case

  defmodule Client do
    use Maxwell.Builder

    middleware Maxwell.Middleware.Json, [encode_func: &Poison.encode/1, decode_func: &Poison.decode/1, decode_content_types: ["text/html"], encode_content_type: "application/json"]
    middleware Maxwell.Middleware.Logger
    middleware Maxwell.Middleware.Opts, [connect_timeout: 3000]

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
        "/use-defined-content-type" ->
          {:ok,
           %{env| status: 200, headers: %{'Content-Type' => 'text/html'}, body: "{\"value\": 124}"}};
        "/not_found_404" ->
          {:ok, %{env|status: 404, body: "404 Not Found"}};
        "/redirection_301" ->
          {:ok, %{env|status: 301, body: "301 Moved Permanently"}};
        "/error" ->
          {:error, "hahahaha"}
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

  test "/use-defined-content-type" do
    assert Client.post!(url: "/use-defined-content-type", body: %{"foo" => "bar"}).body == %{"value" => 124}
  end

  test "404 NOT FOUND" do
    assert Client.post!(url: "/not_found_404", body: %{"foo" => "bar"}).status == 404
  end

  test "301 Moved Permanently" do
    assert Client.post!(url: "/redirection_301", body: %{"foo" => "bar"}).status == 301
  end

  test "error" do
    assert Client.post(url: "/error", body: %{"foo" => "bar"}) == {:error, "hahahaha"}
  end
end

defmodule DecodeJsonTest do
  use ExUnit.Case

  defmodule Client do
    use Maxwell.Builder, ~w(post)

    middleware Maxwell.Middleware.EncodeJson, [encode_content_type: "text/javascript"]
    middleware Maxwell.Middleware.DecodeJson

    adapter fn (env) -> {:ok, %{env|status: 200}} end

  end

  test "DecodeJsonTest add custom header" do
    response = Client.post!(body: %{test: "test"})
    assert response.headers == %{'Content-Type': "text/javascript"}
    assert response.status == 200
  end

  test "JsonTest with invalid options encode_func" do
    assert_raise ArgumentError, "Json Middleware :encode_func only accpect function/1", fn ->
      Code.eval_string """
      defmodule TAtom do
      use Maxwell.Builder, [:get, :post]
      middleware Maxwell.Middleware.Json, [encode_func: :atom]
      end
      raise "ok"
      """
    end
  end

  test "JsonTest with invalid options encode_content_type" do
    assert_raise ArgumentError, "Json Middleware :encode_content_types only accpect string", fn ->
      Code.eval_string """
      defmodule TAtom do
      use Maxwell.Builder, [:get, :post]
      middleware Maxwell.Middleware.Json, [encode_content_type: :atom]
      end
      raise "ok"
      """
    end
  end

  test "JsonTest with invalid options decode_func" do
    assert_raise ArgumentError, "Json Middleware :decode_func only accpect function/1", fn ->
      Code.eval_string """
      defmodule TAtom do
      use Maxwell.Builder, [:get, :post]
      middleware Maxwell.Middleware.Json, [decode_func: 123]
      end
      raise "ok"
      """
    end
  end

  test "JsonTest with invalid options decode_content_types" do
    assert_raise ArgumentError, "Json Middleware :decode_content_types only accpect lists", fn ->
      Code.eval_string """
      defmodule TAtom do
      use Maxwell.Builder, [:get, :post]
      middleware Maxwell.Middleware.Json, [decode_content_types: "application/json"]
      end
      raise "ok"
      """
    end
  end

  test "JsonTest with wrong options" do
    assert_raise ArgumentError, "Json Middleware Options don't accpect wrong_option", fn ->
      Code.eval_string """
      defmodule TAtom do
      use Maxwell.Builder, [:get, :post]
      middleware Maxwell.Middleware.Json, [wrong_option: "application/json"]
      end
      raise "ok"
      """
    end
  end

  test "EncodeJsonTest with invalid options encode_func " do
    assert_raise ArgumentError, "EncodeJson :encode_func only accpect function/1", fn ->
      Code.eval_string """
      defmodule TAtom do
      use Maxwell.Builder, [:get, :post]
      middleware Maxwell.Middleware.EncodeJson, [encode_func: "application/json"]
      end
      raise "ok"
      """
    end
  end

  test "EncodeJsonTest with invalid options encode_content_type" do
    assert_raise ArgumentError, "EncodeJson :encode_content_types only accpect string", fn ->
      Code.eval_string """
      defmodule TAtom do
      use Maxwell.Builder, [:get, :post]
      middleware Maxwell.Middleware.EncodeJson, [encode_content_type: 1234]
      end
      raise "ok"
      """
    end
  end

  test "EncodeJsonTest with wrong option" do
    assert_raise ArgumentError, "EncodeJson Options don't accpect wrong_option (:encode_func and :encode_content_type)", fn ->
      Code.eval_string """
      defmodule TAtom do
      use Maxwell.Builder, [:get, :post]
      middleware Maxwell.Middleware.EncodeJson, [wrong_option: 1234]
      end
      raise "ok"
      """
    end
  end

  test "DecodeJsonTest with invalid options decode_func " do
    assert_raise ArgumentError, "DecodeJson :decode_func only accpect function/1", fn ->
      Code.eval_string """
      defmodule TAtom do
      use Maxwell.Builder, [:get, :post]
      middleware Maxwell.Middleware.DecodeJson, [decode_func: "application/json"]
      end
      raise "ok"
      """
    end
  end

  test "DecodeJsonTest with invalid options decode_content_types" do
    assert_raise ArgumentError, "DecodeJson :decode_content_types only accpect lists", fn ->
      Code.eval_string """
      defmodule TAtom do
      use Maxwell.Builder, [:get, :post]
      middleware Maxwell.Middleware.DecodeJson, [decode_content_types: 1234]
      end
      raise "ok"
      """
    end
  end

  test "DecodeJsonTest with wrong option" do
    assert_raise ArgumentError, "DecodeJson Options don't accpect wrong_option (:decode_func and :decode_content_types)", fn ->
      Code.eval_string """
      defmodule TAtom do
      use Maxwell.Builder, [:get, :post]
      middleware Maxwell.Middleware.DecodeJson, [wrong_option: 1234]
      end
      raise "ok"
      """
    end
  end

end

