defmodule Maxwell.IbrowseTest do
  use Maxwell.Adapter.TestHelper, adapter: Maxwell.Adapter.Ibrowse
end

defmodule Maxwell.IbrowseMockTest do
  use ExUnit.Case, async: false
  import Maxwell.Conn
  import Mock

  defmodule Client do
    use Maxwell.Builder
    adapter Maxwell.Adapter.Ibrowse

    middleware Maxwell.Middleware.BaseUrl, "http://httpbin.org"
    middleware Maxwell.Middleware.Opts, [connect_timeout: 5000]
    middleware Maxwell.Middleware.Json

    def get_ip_test() do
      "/ip" |> put_path |> Client.get!
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
      |> put_query_string("foo", "bar")
      |> put_option(:inactivity_timeout, 1000)
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

    def file_test(filepath) do
      "/post"
      |> put_path
      |> put_req_body({:file, filepath})
      |> Client.post!
    end

    def file_test(filepath, content_type) do
      "/post"
      |> put_path
      |> put_req_body({:file, filepath})
      |> put_req_header("content-type", content_type)
      |> Client.post!
    end

    def stream_test() do
      "/post"
      |> put_path
      |> put_req_header("content-type", "application/vnd.lotus-1-2-3")
      |> put_req_header("content-length", 6)
      |> put_req_body(Stream.map(["1", "2", "3"], fn(x) -> List.duplicate(x, 2) end))
      |> Client.post!
    end

  end

  if Code.ensure_loaded?(:rand) do
    setup do
      :rand.seed(:exs1024, {:erlang.phash2([node()]), :erlang.monotonic_time, :erlang.unique_integer})
      :ok
    end
  else
    setup do
      :random.seed(:erlang.phash2([node()]), :erlang.monotonic_time, :erlang.unique_integer)
      :ok
    end
  end

  test_with_mock "sync request", :ibrowse,
    [send_req:
     fn(_,_,_,_,_) ->
       {:ok, '200',
        [{'Server', 'nginx'}, {'Date', 'Sun, 18 Dec 2016 03:02:14 GMT'},
         {'Content-Type', 'application/json'}, {'Content-Length', '33'},
         {'Connection', 'keep-alive'}, {'Access-Control-Allow-Origin', '*'},
         {'Access-Control-Allow-Credentials', 'true'}],
        '{\n  "origin": "183.240.20.213"\n}\n'}
     end] do
    assert Client.get_ip_test |> Maxwell.Conn.get_status == 200
  end

  test_with_mock "encode decode json test", :ibrowse,
    [send_req:
     fn(_,_,_,_,_) ->
       {:ok, '200',
        [{'Server', 'nginx'}, {'Date', 'Sun, 18 Dec 2016 03:12:20 GMT'},
         {'Content-Type', 'application/json'}, {'Content-Length', '383'},
         {'Connection', 'keep-alive'}, {'Access-Control-Allow-Origin', '*'},
         {'Access-Control-Allow-Credentials', 'true'}],
        '{\n  "args": {}, \n  "data": "{\\"josnkey2\\":\\"jsonvalue2\\",\\"josnkey1\\":\\"jsonvalue1\\"}", \n  "files": {}, \n  "form": {}, \n  "headers": {\n    "Content-Length": "49", \n    "Content-Type": "application/json", \n    "Host": "httpbin.org"\n  }, \n  "json": {\n    "josnkey1": "jsonvalue1", \n    "josnkey2": "jsonvalue2"\n  }, \n  "origin": "183.240.20.213", \n  "url": "http://httpbin.org/post"\n}\n'}
     end] do
    result = %{"josnkey1" => "jsonvalue1", "josnkey2" => "jsonvalue2"} |> Client.encode_decode_json_test
    assert result == %{"josnkey1" => "jsonvalue1", "josnkey2" => "jsonvalue2"}

  end

  test_with_mock "mutilpart body file", :ibrowse,
    [send_req:
     fn(_,_,_,_,_) ->
       {:ok, '200',
        [{'Server', 'nginx'}, {'Date', 'Sun, 18 Dec 2016 03:13:54 GMT'},
         {'Content-Type', 'application/json'}, {'Content-Length', '392'},
         {'Connection', 'keep-alive'}, {'Access-Control-Allow-Origin', '*'},
         {'Access-Control-Allow-Credentials', 'true'}],
        '{\n  "args": {}, \n  "data": "", \n  "files": {\n    "file": "#!/usr/bin/env bash\\necho \\"test multipart file\\"\\n"\n  }, \n  "form": {}, \n  "headers": {\n    "Content-Length": "279", \n    "Content-Type": "multipart/form-data; boundary=---------------------------hknycbtpcxdlluen", \n    "Host": "httpbin.org"\n  }, \n  "json": null, \n  "origin": "183.240.20.213", \n  "url": "http://httpbin.org/post"\n}\n'}
     end] do
    conn = Client.multipart_test
    assert get_resp_body(conn, "files") == %{"file" => "#!/usr/bin/env bash\necho \"test multipart file\"\n"}
  end

  test_with_mock "mutilpart body file extra headers", :ibrowse,
    [send_req:
     fn(_,_,_,_,_) ->
       {:ok, '200',
        [{'Server', 'nginx'}, {'Date', 'Sun, 18 Dec 2016 03:15:23 GMT'},
         {'Content-Type', 'application/json'}, {'Content-Length', '392'},
         {'Connection', 'keep-alive'}, {'Access-Control-Allow-Origin', '*'},
         {'Access-Control-Allow-Credentials', 'true'}],
        '{\n  "args": {}, \n  "data": "", \n  "files": {\n    "file": "#!/usr/bin/env bash\\necho \\"test multipart file\\"\\n"\n  }, \n  "form": {}, \n  "headers": {\n    "Content-Length": "273", \n    "Content-Type": "multipart/form-data; boundary=---------------------------myyesqvzohlzgweh", \n    "Host": "httpbin.org"\n  }, \n  "json": null, \n  "origin": "183.240.20.213", \n  "url": "http://httpbin.org/post"\n}\n'}
     end] do
    conn = Client.multipart_with_extra_header_test
    assert get_resp_body(conn, "files") == %{"file" => "#!/usr/bin/env bash\necho \"test multipart file\"\n"}
  end

  test_with_mock "send file without content-type", :ibrowse,
    [send_req:
     fn(_,_,_,_,_) ->
       {:ok, '200',
        [{'Server', 'nginx'}, {'Date', 'Sun, 18 Dec 2016 03:16:37 GMT'},
         {'Content-Type', 'application/json'}, {'Content-Length', '316'},
         {'Connection', 'keep-alive'}, {'Access-Control-Allow-Origin', '*'},
         {'Access-Control-Allow-Credentials', 'true'}],
        '{\n  "args": {}, \n  "data": "#!/usr/bin/env bash\\necho \\"test multipart file\\"\\n", \n  "files": {}, \n  "form": {}, \n  "headers": {\n    "Content-Length": "47", \n    "Content-Type": "application/x-sh", \n    "Host": "httpbin.org"\n  }, \n  "json": null, \n  "origin": "183.240.20.213", \n  "url": "http://httpbin.org/post"\n}\n'}
     end] do
    conn = Client.file_test("test/maxwell/multipart_test_file.sh")
    assert get_resp_body(conn, "data") == "#!/usr/bin/env bash\necho \"test multipart file\"\n"
  end

  test_with_mock "send file with content-type", :ibrowse,
    [send_req:
     fn(_,_,_,_,_) ->
       {:ok, '200',
        [{'Server', 'nginx'}, {'Date', 'Sun, 18 Dec 2016 03:17:51 GMT'},
         {'Content-Type', 'application/json'}, {'Content-Length', '316'},
         {'Connection', 'keep-alive'}, {'Access-Control-Allow-Origin', '*'},
         {'Access-Control-Allow-Credentials', 'true'}],
        '{\n  "args": {}, \n  "data": "#!/usr/bin/env bash\\necho \\"test multipart file\\"\\n", \n  "files": {}, \n  "form": {}, \n  "headers": {\n    "Content-Length": "47", \n    "Content-Type": "application/x-sh", \n    "Host": "httpbin.org"\n  }, \n  "json": null, \n  "origin": "183.240.20.213", \n  "url": "http://httpbin.org/post"\n}\n'}
     end] do
    conn = Client.file_test("test/maxwell/multipart_test_file.sh", "application/x-sh")
    assert get_resp_body(conn, "data") == "#!/usr/bin/env bash\necho \"test multipart file\"\n"
  end

  test_with_mock "send stream", :ibrowse,
    [send_req:
     fn(_,_,_,_,_) ->
       {:ok, '200',
        [{'Server', 'nginx'}, {'Date', 'Sun, 18 Dec 2016 03:21:15 GMT'},
         {'Content-Type', 'application/json'}, {'Content-Length', '283'},
         {'Connection', 'keep-alive'}, {'Access-Control-Allow-Origin', '*'},
         {'Access-Control-Allow-Credentials', 'true'}],
        '{\n  "args": {}, \n  "data": "112233", \n  "files": {}, \n  "form": {}, \n  "headers": {\n    "Content-Length": "6", \n    "Content-Type": "application/vnd.lotus-1-2-3", \n    "Host": "httpbin.org"\n  }, \n  "json": 112233, \n  "origin": "183.240.20.213", \n  "url": "http://httpbin.org/post"\n}\n'}
     end] do
    conn = Client.stream_test
    assert get_resp_body(conn, "data") == "112233"
  end

  test_with_mock "user-agent header test", :ibrowse,
    [send_req:
     fn(_,_,_,_,_) ->
       {:ok, '200',
        [{'Server', 'nginx'}, {'Date', 'Sun, 18 Dec 2016 03:21:57 GMT'},
         {'Content-Type', 'application/json'}, {'Content-Length', '27'},
         {'Connection', 'keep-alive'}, {'Access-Control-Allow-Origin', '*'},
         {'Access-Control-Allow-Credentials', 'true'}],
        '{\n  "user-agent": "test"\n}\n'}
     end] do
    assert "test" |> Client.user_agent_test == "test"
  end

  test_with_mock "/put", :ibrowse,
    [send_req:
     fn(_,_,_,_,_) ->
       {:ok, '200',
        [{'Server', 'nginx'}, {'Date', 'Sun, 18 Dec 2016 03:23:00 GMT'},
         {'Content-Type', 'application/json'}, {'Content-Length', '303'},
         {'Connection', 'keep-alive'}, {'Access-Control-Allow-Origin', '*'},
         {'Access-Control-Allow-Credentials', 'true'}],
        '{\n  "args": {}, \n  "data": "{\\"key\\":\\"value\\"}", \n  "files": {}, \n  "form": {}, \n  "headers": {\n    "Content-Length": "15", \n    "Content-Type": "application/json", \n    "Host": "httpbin.org"\n  }, \n  "json": {\n    "key": "value"\n  }, \n  "origin": "183.240.20.213", \n  "url": "http://httpbin.org/put"\n}\n'}
     end] do
    assert %{"key" => "value"} |> Client.put_json_test == "{\"key\":\"value\"}"
  end

  test_with_mock "/delete", :ibrowse,
    [send_req:
     fn(_,_,_,_,_) ->
       {:ok, '200',
        [{'Server', 'nginx'}, {'Date', 'Sun, 18 Dec 2016 03:24:08 GMT'},
         {'Content-Type', 'application/json'}, {'Content-Length', '225'},
         {'Connection', 'keep-alive'}, {'Access-Control-Allow-Origin', '*'},
         {'Access-Control-Allow-Credentials', 'true'}],
        '{\n  "args": {}, \n  "data": "", \n  "files": {}, \n  "form": {}, \n  "headers": {\n    "Content-Length": "0", \n    "Host": "httpbin.org"\n  }, \n  "json": null, \n  "origin": "183.240.20.213", \n  "url": "http://httpbin.org/delete"\n}\n'}
     end] do
    assert Client.delete_test == ""
  end

  test_with_mock "adapter return error", :ibrowse,
    [send_req:
     fn(_,_,_,_,_) ->
       {:error, :req_timedout}
     end] do
    {:error, :req_timedout, conn} = Client.timeout_test
    assert conn.state == :error
  end

end

