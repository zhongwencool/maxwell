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
      Maxwell.Middleware.Logger.call(conn,fn(x) ->{:error, "bad request", %{x| status: 400}} end, :info) end
    output301 = capture_log fn -> Maxwell.Middleware.Logger.call(conn, fn(x) -> %{x| status: 301} end, :info) end
    output404 = capture_log fn -> Maxwell.Middleware.Logger.call(conn, fn(x) -> %{x| status: 404} end, :info) end
    output500 = capture_log fn -> Maxwell.Middleware.Logger.call(conn, fn(x) -> %{x| status: 500} end, :info) end
    outputok  = capture_log fn -> Maxwell.Middleware.Logger.call(conn, fn(x) -> x end, :info) end
    assert outputstr =~ ~r"\e\[22m\n\d+:\d+:\d+.\d+ \[info\]  GET http://example.com>> \e\[31mERROR: <<\"bad request\">>\n\e\[0m"

    assert output301 =~ ~r"\e\[22m\n\d+:\d+:\d+.\d+ \[info\]  get http://example.com <<<\e\[33m301\(\d+.\d+ms\)\e\[0m\n%Maxwell.Conn\{method: :get, opts: \[\], path: \"\", query_string: \%\{\}, req_body: nil, req_headers: \%\{\}, resp_body: \"\", resp_headers: \%\{\}, state: :unsent, status: 301, url: \"http://example.com\"\}\n\e\[0m"

    assert output404 =~ ~r"\e\[22m\n\d+:\d+:\d+.\d+ \[info\]  get http://example.com <<<\e\[31m404\(\d+.\d+ms\)\e\[0m\n%Maxwell.Conn\{method: :get, opts: \[\], path: \"\", query_string: \%\{\}, req_body: nil, req_headers: \%\{\}, resp_body: \"\", resp_headers: \%\{\}, state: :unsent, status: 404, url: \"http://example.com\"\}\n\e\[0m"

    assert output500 =~ ~r"\e\[22m\n\d+:\d+:\d+.\d+ \[info\]  get http://example.com <<<\e\[31m500\(\d+.\d+ms\)\e\[0m\n%Maxwell.Conn\{method: :get, opts: \[\], path: \"\", query_string: \%\{\}, req_body: nil, req_headers: \%\{\}, resp_body: \"\", resp_headers: \%\{\}, state: :unsent, status: 500, url: \"http://example.com\"\}\n\e\[0m"

    assert outputok  =~ ~r"\e\[22m\n\d+:\d+:\d+.\d+ \[info\]  get http://example.com <<<\e\[32m200\(\d+.\d+ms\)\e\[0m\n%Maxwell.Conn\{method: :get, opts: \[\], path: \"\", query_string: \%\{\}, req_body: nil, req_headers: \%\{\}, resp_body: \"\", resp_headers: \%\{\}, state: :unsent, status: 200, url: \"http://example.com\"}\n\e\[0m"

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
    assert_raise ArgumentError, "Logger Middleware :log_level only accpect atom", fn ->
      defmodule TAtom1 do
        use Maxwell.Builder, [:get, :post]
        middleware Maxwell.Middleware.Logger, [log_level: 1234]
      end
      raise "ok"
    end
  end

  test "Middleware.Logger with wrong options" do
    assert_raise ArgumentError, "Logger Middleware Options don't accpect wrong_option (:log_level)", fn ->
      defmodule TAtom2 do
        use Maxwell.Builder, [:get, :post]
        middleware Maxwell.Middleware.Logger, [wrong_option: :haah]
      end
      raise "ok"
    end
  end

end

