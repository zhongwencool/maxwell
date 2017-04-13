defmodule LoggerTest do
  use ExUnit.Case
  import Maxwell.Middleware.TestHelper
  import ExUnit.CaptureLog
  alias Maxwell.Conn

  test "Middleware Logger Request" do
    conn = request(Maxwell.Middleware.Logger, %Conn{url: "/path"}, [])
    assert conn == %Conn{url: "/path"}
  end

  test "Middleware Logger Response" do
    conn = response(Maxwell.Middleware.Logger, %Conn{url: "/path"}, [])
    assert conn == %Conn{url: "/path"}
  end

  test "Logger Call" do
    conn = %Conn{method: :get, url: "http://example.com", status: 200}
    outputstr = capture_log fn ->
      Maxwell.Middleware.Logger.call(conn,fn(x) ->{:error, "bad request", %{x| status: 400}} end, [default: :info])
    end
    output301 = capture_log fn -> Maxwell.Middleware.Logger.call(conn, fn(x) -> %{x| status: 301} end, [default: :error]) end
    output404 = capture_log fn -> Maxwell.Middleware.Logger.call(conn, fn(x) -> %{x| status: 404} end, [{404, :debug}]) end
    output500 = capture_log fn -> Maxwell.Middleware.Logger.call(conn, fn(x) -> %{x| status: 500} end, [{500..599, :warn}, {:default, :error}]) end
    outputok  = capture_log fn -> Maxwell.Middleware.Logger.call(conn, fn(x) -> x end, [default: :info]) end
    nooutput  = capture_log fn -> Maxwell.Middleware.Logger.call(conn, fn(x) -> x end, [{400..599, :info}]) end
    assert outputstr =~ ~r"\e\[31m\n\d+:\d+:\d+.\d+ \[error\] GET http://example.com>> \e\[31mERROR: \"bad request\"\n\e\[0m"

    assert output301 =~ ~r"\e\[31m\n\d+:\d+:\d+.\d+ \[error\] get http://example.com <<<\e\[31m301\(\d+ms\)\e\[0m\n%Maxwell.Conn\{method: :get, opts: \[\], path: \"\", private: \%\{\}, query_string: \%\{\}, req_body: nil, req_headers: \%\{\}, resp_body: \"\", resp_headers: \%\{\}, state: :unsent, status: 301, url: \"http://example.com\"\}\n\e\[0m"

    assert output404 =~ ~r"\e\[36m\n\d+:\d+:\d+.\d+ \[debug\] get http://example.com <<<\e\[36m404\(\d+ms\)\e\[0m\n%Maxwell.Conn\{method: :get, opts: \[\], path: \"\", private: \%\{\}, query_string: \%\{\}, req_body: nil, req_headers: \%\{\}, resp_body: \"\", resp_headers: \%\{\}, state: :unsent, status: 404, url: \"http://example.com\"\}\n\e\[0m"

    assert output500 =~ ~r"\e\[33m\n\d+:\d+:\d+.\d+ \[warn\]  get http://example.com <<<\e\[33m500\(\d+ms\)\e\[0m\n%Maxwell.Conn\{method: :get, opts: \[\], path: \"\", private: \%\{\}, query_string: \%\{\}, req_body: nil, req_headers: \%\{\}, resp_body: \"\", resp_headers: \%\{\}, state: :unsent, status: 500, url: \"http://example.com\"\}\n\e\[0m"

    assert outputok  =~ ~r"\e\[22m\n\d+:\d+:\d+.\d+ \[info\]  get http://example.com <<<\e\[22m200\(\d+ms\)\e\[0m\n%Maxwell.Conn\{method: :get, opts: \[\], path: \"\", private: \%\{\}, query_string: \%\{\}, req_body: nil, req_headers: \%\{\}, resp_body: \"\", resp_headers: \%\{\}, state: :unsent, status: 200, url: \"http://example.com\"}\n\e\[0m"

    assert nooutput == ""
  end

  test "Change Middleware Logger's log_level" do
    assert_raise RuntimeError, "ok", fn ->
      defmodule TAtom0 do
        use Maxwell.Builder, [:get, :post]
        middleware Maxwell.Middleware.Logger, [log_level: :debug]
      end
      raise "ok"
    end
  end

  test "Middleware Logger with invalid log_level" do
    assert_raise ArgumentError, ~r/Logger Middleware: level only accepts/, fn ->
      defmodule TAtom1 do
        use Maxwell.Builder, [:get, :post]
        middleware Maxwell.Middleware.Logger, [log_level: 1234]
      end
      raise "ok"
    end
  end

  test "Middleware.Logger with wrong options" do
    assert_raise ArgumentError, "Logger Middleware Options doesn't accept wrong_option (:log_level)", fn ->
      defmodule TAtom2 do
        use Maxwell.Builder, [:get, :post]
        middleware Maxwell.Middleware.Logger, [wrong_option: :haah]
      end
      raise "ok"
    end
  end

  test "Complex log_level for Middleware Logger 1" do
    assert_raise RuntimeError, "ok", fn ->
      defmodule TAtom3 do
        use Maxwell.Builder, [:get, :post]
        middleware Maxwell.Middleware.Logger, log_level: [
          error: 400..599
        ]
      end
      raise "ok"
    end
  end

  test "Complex log_level for Middleware Logger 2" do
    assert_raise RuntimeError, "ok", fn ->
      defmodule TAtom4 do
        use Maxwell.Builder, [:get, :post]
        middleware Maxwell.Middleware.Logger, log_level: [
          info: [1..99, 100, 200..299],
          warn: 300..399,
          error: :default
        ]
      end
      raise "ok"
    end
  end

  test "Complex log_level with wrong status code" do
    assert_raise ArgumentError, "Logger Middleware: status code only accepts Integer and Range.", fn ->
      defmodule TStatusCode do
        use Maxwell.Builder, [:get, :post]
        middleware Maxwell.Middleware.Logger, log_level: [
          info: ["100"],
        ]
      end
      raise "ok"
    end
  end

  test "Complex log_level with duplicated default level" do
    assert ExUnit.CaptureLog.capture_log(fn ->
      defmodule TDefaultLevel1 do
        use Maxwell.Builder, [:get, :post]
        middleware Maxwell.Middleware.Logger, log_level: [
          info: :default,
          info: :default,
        ]
      end
    end) =~ ~r"\e\[33m\n\d+:\d+:\d+.\d+ \[warn\]  Logger Middleware: default level defined multiple times.\n\e\[0m"
  end

  test "Complex log_level with conflictive default level" do
    assert_raise ArgumentError, "Logger Middleware: default level conflict.", fn ->
      defmodule TDefaultLevel2 do
        use Maxwell.Builder, [:get, :post]
        middleware Maxwell.Middleware.Logger, log_level: [
          info: :default,
          error: :default,
        ]
      end
      raise "ok"
    end
  end

end
