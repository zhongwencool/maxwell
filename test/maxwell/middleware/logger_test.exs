defmodule LoggerTest do
  use ExUnit.Case
  import Maxwell.TestHelper

  test "Middleware.Logger request" do
    env = request(Maxwell.Middleware.Logger, %Maxwell.Conn{url: "/path"}, [])
    assert env == %Maxwell.Conn{url: "/path"}
  end

  test "Middleware.Logger response" do
    {:ok, env} = response(Maxwell.Middleware.Logger, {:ok, %Maxwell.Conn{url: "/path"}}, [])
    assert env == %Maxwell.Conn{url: "/path"}
  end

  test "Middleware.Logger with invalid log_level" do
    assert_raise ArgumentError, "Logger Middleware :log_level only accpect atom", fn ->
      Code.eval_string """
      defmodule TAtom do
      use Maxwell.Builder, [:get, :post]
      middleware Maxwell.Middleware.Logger, [log_level: 1234]
      end
      raise "ok"
      """
    end
  end

  test "Middleware.Logger with invalid log_body_max_len" do
    assert_raise ArgumentError, "Logger Middleware :log_body_max_len only accpect integer", fn ->
      Code.eval_string """
      defmodule TAtom do
      use Maxwell.Builder, [:get, :post]
      middleware Maxwell.Middleware.Logger, [log_body_max_len: :haah]
      end
      raise "ok"
      """
    end
  end

  test "Middleware.Logger with wrong options" do
    assert_raise ArgumentError, "Logger Middleware Options don't accpect wrong_option (:log_body_max_len, :log_level)", fn ->
      Code.eval_string """
      defmodule TAtom do
      use Maxwell.Builder, [:get, :post]
      middleware Maxwell.Middleware.Logger, [wrong_option: :haah]
      end
      raise "ok"
      """
    end
  end

end

