defmodule JsonTest do
  use ExUnit.Case

  defmodule ModuleAdapter do
    def call(conn) do
      conn = %{conn|state: :sent}
      case conn.path do
        "/decode" ->
          {:ok,
            %{conn| status: 200, resp_headers: %{"Content-Type" => "application/json"}, resp_body: "{\"value\": 123}"}}
        "/encode" ->
          {:ok,
            %{conn| status: 200, resp_headers: %{"Content-Type" => "application/json"}, resp_body: conn.req_body |> String.replace("foo", "baz")}}
        "/empty" ->
          {:ok,
            %{conn| status: 200, resp_headers: %{"Content-Type" => "application/json"}, resp_body: nil}}
        "/invalid-content-type" ->
          {:ok,
            %{conn| status: 200, resp_headers: %{"Content-Type" => "text/plain"}, resp_body: "hello"}}
        "/use-defined-content-type" ->
          {:ok,
           %{conn| status: 200, resp_headers: %{"Content-Type" => "text/html"}, resp_body: "{\"value\": 124}"}};
        "/not_found_404" ->
          {:ok, %{conn|status: 404, resp_body: "404 Not Found"}};
        "/redirection_301" ->
          {:ok, %{conn|status: 301, resp_body: "301 Moved Permanently"}};
        "/error" ->
          {:error, "hahahaha"}
      end
    end
  end

  defmodule Client do
    use Maxwell.Builder

    middleware Maxwell.Middleware.Json, [encode_func: &Poison.encode/1, decode_func: &Poison.decode/1,
                                         decode_content_types: ["text/html"], encode_content_type: "application/json"]
    middleware Maxwell.Middleware.Logger
    middleware Maxwell.Middleware.Opts, [connect_timeout: 3000]

    adapter ModuleAdapter
  end

  alias Maxwell.Conn
  test "decode JSON body" do
    assert Conn.put_path("/decode") |> Client.get!|> Conn.get_resp_body == %{"value" => 123}
  end

  test "do not decode empty body" do
    assert Conn.put_path("/empty") |> Client.get!|> Conn.get_resp_body == nil
  end

  test "decode only if Content-Type is application/json" do
    assert "/invalid-content-type" |> Conn.put_path |> Client.get!|> Conn.get_resp_body == "hello"
  end

  test "encode body as JSON" do
    body =
      "/encode"
      |> Conn.put_path
      |> Conn.put_req_body(%{"foo" => "bar"})
      |> Client.post!
      |> Conn.get_resp_body
    assert body == %{"baz" => "bar"}
  end

  test "/use-defined-content-type" do
    body =
      "/use-defined-content-type"
      |> Conn.put_path
      |> Conn.put_req_body(%{"foo" => "bar"})
      |> Client.post!
      |> Conn.get_resp_body
    assert body == %{"value" => 124}
  end

  test "404 NOT FOUND" do
    {:ok, conn} =
      "/not_found_404"
      |> Conn.put_path
      |> Conn.put_req_body(%{"foo" => "bar"})
      |> Client.post
    assert Conn.get_status(conn) == 404
  end

  test "301 Moved Permanently" do
    {:ok, conn} =
      "/redirection_301"
      |> Conn.put_path
      |> Conn.put_req_body(%{"foo" => "bar"})
      |> Client.post

    assert Conn.get_status(conn) == 301
  end

  test "error" do
    result =
      "/error"
      |> Conn.put_path
      |> Conn.put_req_body(%{"foo" => "bar"})
      |> Client.post
    assert result == {:error, "hahahaha"}
  end
end

defmodule ModuleAdapter2 do
  def call(conn) do
    {:ok, %{conn|status: 200,
            state: :sent,
            resp_headers: %{"Content-Type" => "text/javascript"},
            resp_body: "{\"value\": 124}"}}
  end
end

defmodule DecodeJsonTest do
  use ExUnit.Case

  defmodule Client do
    use Maxwell.Builder, ~w(post)

    middleware Maxwell.Middleware.EncodeJson, [encode_content_type: "text/javascript"]
    middleware Maxwell.Middleware.DecodeJson

    adapter ModuleAdapter2

  end

  alias Maxwell.Conn
  test "DecodeJsonTest add custom header" do
    response = %{test: "test"} |> Conn.put_req_body |> Client.post!
    assert Conn.get_resp_header(response) == %{"Content-Type" => "text/javascript"}
    assert Conn.get_status(response) == 200
  end

  test "JsonTest with invalid options encode_func" do
    assert_raise ArgumentError, "Json Middleware :encode_func only accpect function/1", fn ->
      Code.eval_string """
      defmodule TAtom1 do
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
      defmodule TAtom2 do
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
      defmodule TAtom3 do
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
      defmodule TAtom4 do
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
      defmodule TAtom5 do
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
      defmodule TAtom6 do
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
      defmodule TAtom7 do
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
      defmodule TAtom8 do
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
      defmodule TAtom9 do
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
      defmodule TAtom10 do
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
      defmodule TAtom11 do
      use Maxwell.Builder, [:get, :post]
      middleware Maxwell.Middleware.DecodeJson, [wrong_option: 1234]
      end
      raise "ok"
      """
    end
  end

end

