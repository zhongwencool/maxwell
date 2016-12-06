defmodule LoggerTest do
  use ExUnit.Case
  import Maxwell.TestHelper
  alias Maxwell.Conn

  test "Middleware Logger Request" do
    conn = request(Maxwell.Middleware.Logger, %Conn{url: "/path"}, [])
    assert conn == %Conn{url: "/path"}
  end

  test "Middleware Logger Response" do
    {:ok, conn} = response(Maxwell.Middleware.Logger, {:ok, %Conn{url: "/path"}}, [])
    assert conn == %Conn{url: "/path"}
  end

  test "Logger Call" do
    conn = %Conn{method: :get, url: "http://example.com", status: 200}
    Maxwell.Middleware.Logger.call(conn, fn(_x) -> {:error, "bad request"} end, :info)
    Maxwell.Middleware.Logger.call(conn, fn(_x) -> {:ok, %{conn| status: 301}} end, :info)
    Maxwell.Middleware.Logger.call(conn, fn(_x) -> {:ok, %{conn| status: 404}} end, :info)
    Maxwell.Middleware.Logger.call(conn, fn(_x) -> {:ok, %{conn| status: 500}} end, :info)
  end

  test "Middleware Logger with invalid log_level" do
    assert_raise ArgumentError, "Logger Middleware :log_level only accpect atom", fn ->
      Code.eval_string """
      defmodule TAtom1 do
      use Maxwell.Builder, [:get, :post]
      middleware Maxwell.Middleware.Logger, [log_level: 1234]
      end
      raise "ok"
      """
    end
  end

  test "Middleware.Logger with wrong options" do
    assert_raise ArgumentError, "Logger Middleware Options don't accpect wrong_option (:log_level)", fn ->
      Code.eval_string """
      defmodule TAtom2 do
      use Maxwell.Builder, [:get, :post]
      middleware Maxwell.Middleware.Logger, [wrong_option: :haah]
      end
      raise "ok"
      """
    end
  end

end

