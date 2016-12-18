defmodule Maxwell.HackneyTest do
  use Maxwell.Adapter.TestHelper, adapter: Maxwell.Adapter.Hackney
end

defmodule Maxwell.HackneyMockTest do
  use ExUnit.Case, async: false
  import Maxwell.Conn
  import Mock

  defmodule Client do
    use Maxwell.Builder

    adapter Maxwell.Adapter.Hackney

    middleware Maxwell.Middleware.BaseUrl, "http://httpbin.org"
    middleware Maxwell.Middleware.Opts, [connect_timeout: 6000]
    middleware Maxwell.Middleware.Json

    def get_ip_test do
      put_path("/ip")
      |> get!
    end
    def encode_decode_json_test(body) do
      "/post"
      |> put_path
      |> put_req_body(body)
      |> post!
      |> get_resp_body("json")
    end

    def user_agent_test(user_agent) do
      "/user-agent"
      |> put_path
      |> put_req_header("user-agent", user_agent)
      |> get!
      |> get_resp_body("user-agent")
    end

    def put_json_test(json) do
      "/put"
      |> put_path
      |> put_req_body(json)
      |> put!
      |> get_resp_body("data")
    end

    def delete_test() do
      "/delete"
      |> put_path
      |> delete!
      |> get_resp_body("data")
    end

    def timeout_test() do
      "/delay/5"
      |> put_path
      |> put_option(:recv_timeout, 1000)
      |> Client.get
    end

    def multipart_test() do
      "/post"
      |> put_path
      |> put_req_body({:multipart, [{:file, "test/maxwell/multipart_test_file.sh"}]})
      |> Client.post!
    end
    def multipart_with_extra_header_test() do
      "/post"
      |> put_path
      |> put_req_body({:multipart, [{:file, "test/maxwell/multipart_test_file.sh", [{"Content-Type", "image/jpeg"}]}]})
      |> Client.post!
    end

    def file_test() do
      "/post"
      |> put_path
      |> put_req_body({:file, "test/maxwell/multipart_test_file.sh"})
      |> Client.post!
    end

    def stream_test() do
      "/post"
      |> put_path
      |> put_req_body(Stream.map(["1", "2", "3"], fn(x) -> List.duplicate(x, 2) end))
      |> Client.post!
    end

  end

  setup do
    :random.seed(:erlang.phash2([node()]), :erlang.monotonic_time, :erlang.unique_integer)
    :ok
  end

  test_with_mock "sync request", :hackney,
    [request: fn(_,_,_,_,_) ->
      {:ok, 200,
       [{"Server", "nginx"}, {"Date", "Sun, 18 Dec 2016 03:33:54 GMT"},
        {"Content-Type", "application/json"}, {"Content-Length", "33"},
        {"Connection", "keep-alive"}, {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Credentials", "true"}], make_ref}
    end,
     body: fn(_) -> {:ok, "{\n  \"origin\": \"183.240.20.213\"\n}\n"} end
    ] do
    assert Client.get_ip_test |> get_status == 200
  end

  test_with_mock "encode decode json", :hackney,
    [request: fn(_,_,_,_,_) ->
      {:ok, 200,
       [{"Server", "nginx"}, {"Date", "Sun, 18 Dec 2016 03:40:41 GMT"},
        {"Content-Type", "application/json"}, {"Content-Length", "419"},
        {"Connection", "keep-alive"}, {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Credentials", "true"}], make_ref}
    end,
     body: fn(_) -> {:ok,
                     "{\n  \"args\": {}, \n  \"data\": \"{\\\"josnkey2\\\":\\\"jsonvalue2\\\",\\\"josnkey1\\\":\\\"jsonvalue1\\\"}\", \n  \"files\": {}, \n  \"form\": {}, \n  \"headers\": {\n    \"Content-Length\": \"49\", \n    \"Content-Type\": \"application/json\", \n    \"Host\": \"httpbin.org\", \n    \"User-Agent\": \"hackney/1.6.3\"\n  }, \n  \"json\": {\n    \"josnkey1\": \"jsonvalue1\", \n    \"josnkey2\": \"jsonvalue2\"\n  }, \n  \"origin\": \"183.240.20.213\", \n  \"url\": \"http://httpbin.org/post\"\n}\n"}
     end
    ] do
    res = %{"josnkey1" => "jsonvalue1", "josnkey2" => "jsonvalue2"} |> Client.encode_decode_json_test
    assert res == %{"josnkey1" => "jsonvalue1", "josnkey2" => "jsonvalue2"}

  end

  test_with_mock "mutilpart body file", :hackney,
    [request: fn(_,_,_,_,_) ->
      {:ok, 200,
       [{"Server", "nginx"}, {"Date", "Sun, 18 Dec 2016 03:42:07 GMT"},
        {"Content-Type", "application/json"}, {"Content-Length", "428"},
        {"Connection", "keep-alive"}, {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Credentials", "true"}], make_ref} end,
     body: fn(_) -> {:ok,
                     "{\n  \"args\": {}, \n  \"data\": \"\", \n  \"files\": {\n    \"file\": \"#!/usr/bin/env bash\\necho \\\"test multipart file\\\"\\n\"\n  }, \n  \"form\": {}, \n  \"headers\": {\n    \"Content-Length\": \"279\", \n    \"Content-Type\": \"multipart/form-data; boundary=---------------------------tvvbujkbhrbruqcy\", \n    \"Host\": \"httpbin.org\", \n    \"User-Agent\": \"hackney/1.6.3\"\n  }, \n  \"json\": null, \n  \"origin\": \"183.240.20.213\", \n  \"url\": \"http://httpbin.org/post\"\n}\n"}
     end ] do
    conn = Client.multipart_test
    assert get_resp_body(conn, "files") == %{"file" => "#!/usr/bin/env bash\necho \"test multipart file\"\n"}
  end

  test_with_mock "mutilpart body file extra headers", :hackney,
    [request: fn(_,_,_,_,_) ->
      {:ok, 200,
       [{"Server", "nginx"}, {"Date", "Sun, 18 Dec 2016 03:45:10 GMT"},
        {"Content-Type", "application/json"}, {"Content-Length", "428"},
        {"Connection", "keep-alive"}, {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Credentials", "true"}], make_ref}
    end, body: fn(_) ->
      {:ok,
       "{\n  \"args\": {}, \n  \"data\": \"\", \n  \"files\": {\n    \"file\": \"#!/usr/bin/env bash\\necho \\\"test multipart file\\\"\\n\"\n  }, \n  \"form\": {}, \n  \"headers\": {\n    \"Content-Length\": \"273\", \n    \"Content-Type\": \"multipart/form-data; boundary=---------------------------dlhrimiytrrvmxqk\", \n    \"Host\": \"httpbin.org\", \n    \"User-Agent\": \"hackney/1.6.3\"\n  }, \n  \"json\": null, \n  \"origin\": \"183.240.20.213\", \n  \"url\": \"http://httpbin.org/post\"\n}\n"}
    end ] do
    conn = Client.multipart_with_extra_header_test
    assert get_resp_body(conn, "files") == %{"file" => "#!/usr/bin/env bash\necho \"test multipart file\"\n"}
  end

  test_with_mock "send file", :hackney,
    [request: fn(_,_,_,_,_) ->
      {:ok, 200,
       [{"Server", "nginx"}, {"Date", "Sun, 18 Dec 2016 03:46:14 GMT"},
        {"Content-Type", "application/json"}, {"Content-Length", "352"},
        {"Connection", "keep-alive"}, {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Credentials", "true"}], make_ref}
    end,
     body: fn(_) ->
       {:ok,
        "{\n  \"args\": {}, \n  \"data\": \"#!/usr/bin/env bash\\necho \\\"test multipart file\\\"\\n\", \n  \"files\": {}, \n  \"form\": {}, \n  \"headers\": {\n    \"Content-Length\": \"47\", \n    \"Content-Type\": \"application/x-sh\", \n    \"Host\": \"httpbin.org\", \n    \"User-Agent\": \"hackney/1.6.3\"\n  }, \n  \"json\": null, \n  \"origin\": \"183.240.20.213\", \n  \"url\": \"http://httpbin.org/post\"\n}\n"}
     end ] do
    conn = Client.file_test
    assert get_resp_body(conn, "data") == "#!/usr/bin/env bash\necho \"test multipart file\"\n"
  end

  test_with_mock "send stream", :hackney,
    [request: fn(_,_,_,_,_) ->
      {:ok, make_ref}
    end,
     send_body: fn(_, _) -> :ok end,
     start_response: fn(_) ->
       {:ok, 200,
        [{"Server", "nginx"}, {"Date", "Sun, 18 Dec 2016 03:47:26 GMT"},
         {"Content-Type", "application/json"}, {"Content-Length", "267"},
         {"Connection", "keep-alive"}, {"Access-Control-Allow-Origin", "*"},
         {"Access-Control-Allow-Credentials", "true"}], make_ref}
     end,
     body: fn(_) ->
       {:ok,
        "{\n  \"args\": {}, \n  \"data\": \"112233\", \n  \"files\": {}, \n  \"form\": {}, \n  \"headers\": {\n    \"Content-Length\": \"6\", \n    \"Host\": \"httpbin.org\", \n    \"User-Agent\": \"hackney/1.6.3\"\n  }, \n  \"json\": 112233, \n  \"origin\": \"183.240.20.213\", \n  \"url\": \"http://httpbin.org/post\"\n}\n"}
     end ] do
    conn = Client.stream_test
    assert get_resp_body(conn, "data") == "112233"
  end

  test_with_mock "send stream error", :hackney,
    [request: fn(_,_,_,_,_) -> {:error, :closed} end,
     send_body: fn(_, _) -> {:error, :closed} end,
     start_response: fn(_) -> {:ok, 200, [], make_ref} end,
     body: fn(_) -> {:ok, "error connection closed"}
     end ] do
    conn = 
    assert_raise(Maxwell.Error,
      "url: http://httpbin.org\npath: \"/post\"\nmethod: post\nstatus: \nreason: :closed\nmodule: Elixir.Maxwell.HackneyMockTest.Client\n",
      fn() -> Client.stream_test |> get_resp_body("data")  end)
  end

  test_with_mock "user-agent header test", :hackney,
    [request: fn(_,_,_,_,_) ->
      {:ok, 200,
       [{"Server", "nginx"}, {"Date", "Sun, 18 Dec 2016 03:52:41 GMT"},
        {"Content-Type", "application/json"}, {"Content-Length", "27"},
        {"Connection", "keep-alive"}, {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Credentials", "true"}], make_ref}
    end,
     body: fn(_) ->
       {:ok, "{\n  \"user-agent\": \"test\"\n}\n"}
     end ] do
    assert "test" |> Client.user_agent_test == "test"
  end

  test_with_mock "/put", :hackney,
    [request: fn(_,_,_,_,_) ->
      {:ok, 200,
       [{"Server", "nginx"}, {"Date", "Sun, 18 Dec 2016 03:54:56 GMT"},
        {"Content-Type", "application/json"}, {"Content-Length", "339"},
        {"Connection", "keep-alive"}, {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Credentials", "true"}], make_ref}
    end, body: fn(_) ->
      {:ok,
       "{\n  \"args\": {}, \n  \"data\": \"{\\\"key\\\":\\\"value\\\"}\", \n  \"files\": {}, \n  \"form\": {}, \n  \"headers\": {\n    \"Content-Length\": \"15\", \n    \"Content-Type\": \"application/json\", \n    \"Host\": \"httpbin.org\", \n    \"User-Agent\": \"hackney/1.6.3\"\n  }, \n  \"json\": {\n    \"key\": \"value\"\n  }, \n  \"origin\": \"183.240.20.213\", \n  \"url\": \"http://httpbin.org/put\"\n}\n"}
    end ] do
    assert %{"key" => "value"} |> Client.put_json_test == "{\"key\":\"value\"}"
  end

  test_with_mock "/delete", :hackney,
    [request: fn(_,_,_,_,_) ->
      {:ok, 200,
       [{"Server", "nginx"}, {"Date", "Sun, 18 Dec 2016 03:53:52 GMT"},
        {"Content-Type", "application/json"}, {"Content-Length", "233"},
        {"Connection", "keep-alive"}, {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Credentials", "true"}], make_ref}
    end, body: fn(_) ->
      {:ok,
       "{\n  \"args\": {}, \n  \"data\": \"\", \n  \"files\": {}, \n  \"form\": {}, \n  \"headers\": {\n    \"Host\": \"httpbin.org\", \n    \"User-Agent\": \"hackney/1.6.3\"\n  }, \n  \"json\": null, \n  \"origin\": \"183.240.20.213\", \n  \"url\": \"http://httpbin.org/delete\"\n}\n"}
    end ] do
    assert Client.delete_test == ""
  end

  test_with_mock "/delete error", :hackney,
    [request: fn(_,_,_,_,_) ->
      {:ok, 200,
       [{"Server", "nginx"}, {"Date", "Sun, 18 Dec 2016 03:53:52 GMT"},
        {"Content-Type", "application/json"}, {"Content-Length", "233"},
        {"Connection", "keep-alive"}, {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Credentials", "true"}], make_ref}
    end, body: fn(_) ->
      {:error, {:closed, ""}}
    end ] do
    assert_raise(Maxwell.Error,
      "url: http://httpbin.org\npath: \"/delete\"\nmethod: delete\nstatus: \nreason: {:closed, \"\"}\nmodule: Elixir.Maxwell.HackneyMockTest.Client\n",
      fn() -> Client.delete_test end)
  end

  test_with_mock "adapter return error", :hackney,
    [request: fn(_,_,_,_,_) -> {:error, :timeout} end] do
    {:error, :timeout, conn} = Client.timeout_test
    assert conn.state == :error
  end

  test_with_mock "Head without body(test hackney.ex return {:ok, status, header})", :hackney,
    [request: fn(_,_,_,_,_) ->
      {:ok, 200,
       [{"Server", "nginx"}, {"Date", "Sun, 18 Dec 2016 03:57:09 GMT"},
        {"Content-Type", "text/html; charset=utf-8"}, {"Content-Length", "12150"},
        {"Connection", "keep-alive"}, {"Access-Control-Allow-Origin", "*"},
        {"Access-Control-Allow-Credentials", "true"}]}
    end] do
    assert Client.head! |> get_resp_body == ""
  end

end

