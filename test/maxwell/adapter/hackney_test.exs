defmodule Maxwell.HackneyTest do
  use Maxwell.Adapter.TestHelper, adapter: Maxwell.Adapter.Hackney
end

defmodule Maxwell.HackneyMockTest do
  use ExUnit.Case, async: false
  use Mimic

  import Maxwell.Conn

  defmodule Client do
    use Maxwell.Builder

    adapter Maxwell.Adapter.Hackney

    middleware Maxwell.Middleware.BaseUrl, "http://httpbin.org"
    middleware Maxwell.Middleware.Opts, [connect_timeout: 6000]
    middleware Maxwell.Middleware.Json

    def get_ip_test do
      "ip" |> new() |> get!()
    end
    def encode_decode_json_test(body) do
      "/post"
      |> new()
      |> put_req_body(body)
      |> post!
      |> get_resp_body("json")
    end

    def user_agent_test(user_agent) do
      "/user-agent"
      |> new()
      |> put_req_header("user-agent", user_agent)
      |> get!
      |> get_resp_body("user-agent")
    end

    def put_json_test(json) do
      "/put"
      |> new()
      |> put_req_body(json)
      |> put!
      |> get_resp_body("data")
    end

    def delete_test() do
      "/delete"
      |> new()
      |> delete!
      |> get_resp_body("data")
    end

    def timeout_test() do
      "/delay/5"
      |> new()
      |> put_option(:recv_timeout, 1000)
      |> Client.get
    end

    def file_test() do
      "/post"
      |> new()
      |> put_req_body({:file, "test/maxwell/multipart_test_file.sh"})
      |> Client.post!
    end

    def stream_test() do
      "/post"
      |> new()
      |> put_req_body(Stream.map(["1", "2", "3"], fn(x) -> List.duplicate(x, 2) end))
      |> Client.post!
    end

  end

  setup do
    :rand.seed(:exs1024, {:erlang.phash2([node()]), :erlang.monotonic_time, :erlang.unique_integer})
    :ok
  end

  test "sync request" do
    :hackney
    |> stub(:request, fn(_,_,_,_,_) ->
      {:ok, 200,
       [{"Server", "nginx"}, {"Date", "Sun, 18 Dec 2016 03:33:54 GMT"},
        {"Content-Type", "application/json"}, {"Content-Length", "33"},
        {"Connection", "keep-alive"}, {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Credentials", "true"}], make_ref()}
    end)
    |> stub(:body, fn(_) -> {:ok, "{\n  \"origin\": \"183.240.20.213\"\n}\n"} end)
    assert Client.get_ip_test |> get_status == 200
  end

  test "encode decode json" do
    :hackney
    |> stub(:request, fn(_,_,_,_,_) ->
      {:ok, 200,
       [{"Server", "nginx"}, {"Date", "Sun, 18 Dec 2016 03:40:41 GMT"},
        {"Content-Type", "application/json"}, {"Content-Length", "419"},
        {"Connection", "keep-alive"}, {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Credentials", "true"}], make_ref()}
    end)
    |> stub(:body, fn _ -> {:ok,
                           "{\n  \"args\": {}, \n  \"data\": \"{\\\"josnkey2\\\":\\\"jsonvalue2\\\",\\\"josnkey1\\\":\\\"jsonvalue1\\\"}\", \n  \"files\": {}, \n  \"form\": {}, \n  \"headers\": {\n    \"Content-Length\": \"49\", \n    \"Content-Type\": \"application/json\", \n    \"Host\": \"httpbin.org\", \n    \"User-Agent\": \"hackney/1.6.3\"\n  }, \n  \"json\": {\n    \"josnkey1\": \"jsonvalue1\", \n    \"josnkey2\": \"jsonvalue2\"\n  }, \n  \"origin\": \"183.240.20.213\", \n  \"url\": \"http://httpbin.org/post\"\n}\n"}
    end)
    res = %{"josnkey1" => "jsonvalue1", "josnkey2" => "jsonvalue2"} |> Client.encode_decode_json_test
    assert res == %{"josnkey1" => "jsonvalue1", "josnkey2" => "jsonvalue2"}

  end

  test "send file" do
    :hackney
    |> stub(:request, fn(_,_,_,_,_) ->
      {:ok, 200,
       [{"Server", "nginx"}, {"Date", "Sun, 18 Dec 2016 03:46:14 GMT"},
        {"Content-Type", "application/json"}, {"Content-Length", "352"},
        {"Connection", "keep-alive"}, {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Credentials", "true"}], make_ref()}
    end)
    |> stub(:body, fn _ ->
      {:ok,
       "{\n  \"args\": {}, \n  \"data\": \"#!/usr/bin/env bash\\necho \\\"test multipart file\\\"\\n\", \n  \"files\": {}, \n  \"form\": {}, \n  \"headers\": {\n    \"Content-Length\": \"47\", \n    \"Content-Type\": \"application/x-sh\", \n    \"Host\": \"httpbin.org\", \n    \"User-Agent\": \"hackney/1.6.3\"\n  }, \n  \"json\": null, \n  \"origin\": \"183.240.20.213\", \n  \"url\": \"http://httpbin.org/post\"\n}\n"}
    end)
    conn = Client.file_test
    assert get_resp_body(conn, "data") == "#!/usr/bin/env bash\necho \"test multipart file\"\n"
  end

  test "send stream" do
    :hackney
    |> stub(:request, fn(_,_,_,_,_) -> {:ok, make_ref()} end)
    |> stub(:send_body, fn _,_ -> :ok end)
    |> stub(:start_response, fn _ ->
      {:ok, 200,
       [{"Server", "nginx"}, {"Date", "Sun, 18 Dec 2016 03:47:26 GMT"},
        {"Content-Type", "application/json"}, {"Content-Length", "267"},
        {"Connection", "keep-alive"}, {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Credentials", "true"}], make_ref()}
    end)
    |> stub(:body, fn _ ->
      {:ok,
       "{\n  \"args\": {}, \n  \"data\": \"112233\", \n  \"files\": {}, \n  \"form\": {}, \n  \"headers\": {\n    \"Content-Length\": \"6\", \n    \"Host\": \"httpbin.org\", \n    \"User-Agent\": \"hackney/1.6.3\"\n  }, \n  \"json\": 112233, \n  \"origin\": \"183.240.20.213\", \n  \"url\": \"http://httpbin.org/post\"\n}\n"}
    end)
    conn = Client.stream_test
    assert get_resp_body(conn, "data") == "112233"
  end

  test "send stream error" do
    :hackney
    |> stub(:request, fn _,_,_,_,_ -> {:error, :closed} end)
    |> stub(:send_body, fn _,_ -> {:error, :closed} end)
    |> stub(:start_response, fn _ -> {:ok, 200, [], make_ref()} end)
    |> stub(:body, fn _ -> {:ok, "error connection closed"} end)

    assert_raise(Maxwell.Error,
      "url: http://httpbin.org\npath: \"/post\"\nmethod: post\nstatus: \nreason: :closed\nmodule: Elixir.Maxwell.HackneyMockTest.Client\n",
      fn -> Client.stream_test |> get_resp_body("data")  end)
  end

  test "user-agent header test" do
    :hackney
    |> stub(:request, fn(_,_,_,_,_) ->
      {:ok, 200,
       [{"Server", "nginx"}, {"Date", "Sun, 18 Dec 2016 03:52:41 GMT"},
        {"Content-Type", "application/json"}, {"Content-Length", "27"},
        {"Connection", "keep-alive"}, {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Credentials", "true"}], make_ref()}
    end)
    |> stub(:body, fn _ ->
      {:ok, "{\n  \"user-agent\": \"test\"\n}\n"}
    end)
    assert "test" |> Client.user_agent_test == "test"
  end

  test "/put" do
    :hackney
    |> stub(:request, fn _,_,_,_,_ ->
      {:ok, 200,
       [{"Server", "nginx"}, {"Date", "Sun, 18 Dec 2016 03:54:56 GMT"},
        {"Content-Type", "application/json"}, {"Content-Length", "339"},
        {"Connection", "keep-alive"}, {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Credentials", "true"}], make_ref()}
    end)
    |> stub(:body, fn _ ->
      {:ok,
       "{\n  \"args\": {}, \n  \"data\": \"{\\\"key\\\":\\\"value\\\"}\", \n  \"files\": {}, \n  \"form\": {}, \n  \"headers\": {\n    \"Content-Length\": \"15\", \n    \"Content-Type\": \"application/json\", \n    \"Host\": \"httpbin.org\", \n    \"User-Agent\": \"hackney/1.6.3\"\n  }, \n  \"json\": {\n    \"key\": \"value\"\n  }, \n  \"origin\": \"183.240.20.213\", \n  \"url\": \"http://httpbin.org/put\"\n}\n"}
    end)
    assert %{"key" => "value"} |> Client.put_json_test == "{\"key\":\"value\"}"
  end

  test "/delete" do
    :hackney
    |> stub(:request, fn _,_,_,_,_ ->
      {:ok, 200,
       [{"Server", "nginx"}, {"Date", "Sun, 18 Dec 2016 03:53:52 GMT"},
        {"Content-Type", "application/json"}, {"Content-Length", "233"},
        {"Connection", "keep-alive"}, {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Credentials", "true"}], make_ref()}
    end)
    |> stub(:body, fn _ ->
      {:ok,
       "{\n  \"args\": {}, \n  \"data\": \"\", \n  \"files\": {}, \n  \"form\": {}, \n  \"headers\": {\n    \"Host\": \"httpbin.org\", \n    \"User-Agent\": \"hackney/1.6.3\"\n  }, \n  \"json\": null, \n  \"origin\": \"183.240.20.213\", \n  \"url\": \"http://httpbin.org/delete\"\n}\n"}
    end)

    assert Client.delete_test == ""
  end

  test "/delete error" do
    :hackney
    |> stub(:request, fn _,_,_,_,_ ->
      {:ok, 200,
       [{"Server", "nginx"}, {"Date", "Sun, 18 Dec 2016 03:53:52 GMT"},
        {"Content-Type", "application/json"}, {"Content-Length", "233"},
        {"Connection", "keep-alive"}, {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Credentials", "true"}], make_ref()}
    end)
    |> stub(:body, fn _ -> {:error, {:closed, ""}} end)

    assert_raise(Maxwell.Error,
      "url: http://httpbin.org\npath: \"/delete\"\nmethod: delete\nstatus: \nreason: {:closed, \"\"}\nmodule: Elixir.Maxwell.HackneyMockTest.Client\n",
      fn -> Client.delete_test end)
  end

  test "adapter return error" do
    :hackney
    |> stub(:request, fn _,_,_,_,_ -> {:error, :timeout} end)

    {:error, :timeout, conn} = Client.timeout_test
    assert conn.state == :error
  end

  test "Head without body(test hackney.ex return {:ok, status, header})" do
    :hackney
    |> stub(:request, fn _,_,_,_,_ ->
      {:ok, 200,
       [{"Server", "nginx"}, {"Date", "Sun, 18 Dec 2016 03:57:09 GMT"},
        {"Content-Type", "text/html; charset=utf-8"}, {"Content-Length", "12150"},
        {"Connection", "keep-alive"}, {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Credentials", "true"}]}
    end)
    assert Client.head! |> get_resp_body == ""
  end
end
