defmodule Maxwell.HttpcTest do
  use Maxwell.Adapter.TestHelper, adapter: Maxwell.Adapter.Httpc
end

defmodule Maxwell.HttpcMockTest do
  use ExUnit.Case, async: false
  import Maxwell.Conn
  use Mimic

  defmodule Client do
    use Maxwell.Builder
    adapter Maxwell.Adapter.Httpc

    middleware Maxwell.Middleware.BaseUrl, "http://httpbin.org"
    middleware Maxwell.Middleware.Opts, connect_timeout: 5000
    middleware Maxwell.Middleware.Json

    def get_ip_test() do
      Client.get!(new("/ip"))
    end

    def encode_decode_json_test(body) do
      new("/post")
      |> put_req_body(body)
      |> post!
      |> get_resp_body("json")
    end

    def user_agent_test(user_agent) do
      new("/user-agent")
      |> put_req_header("user-agent", user_agent)
      |> get!
      |> get_resp_body("user-agent")
    end

    def put_json_test(json) do
      new("/put")
      |> put_req_body(json)
      |> put!
      |> get_resp_body("data")
    end

    def delete_test() do
      new("/delete")
      |> delete!
      |> get_resp_body("data")
    end

    def normalized_error_test() do
      get(new("http://broken.local"))
    end

    def timeout_test() do
      new("/delay/2")
      |> put_option(:timeout, 1000)
      |> Client.get()
    end

    def file_test(filepath) do
      new("/post")
      |> put_req_body({:file, filepath})
      |> Client.post!()
    end

    def file_test(filepath, content_type) do
      new("/post")
      |> put_req_body({:file, filepath})
      |> put_req_header("content-type", content_type)
      |> Client.post!()
    end

    def stream_test() do
      new("/post")
      |> put_req_header("content-type", "application/vnd.lotus-1-2-3")
      |> put_req_header("content-length", 6)
      |> put_req_body(Stream.map(["1", "2", "3"], fn x -> List.duplicate(x, 2) end))
      |> Client.post!()
    end
  end

  setup do
    :rand.seed(
      :exs1024,
      {:erlang.phash2([node()]), :erlang.monotonic_time(), :erlang.unique_integer()}
    )

    :ok
  end

  test "sync request" do
    :httpc
    |> stub(:request, fn _, _, _, _ ->
      {:ok,
       {{'HTTP/1.1', 200, 'OK'},
        [
          {'connection', 'keep-alive'},
          {'date', 'Sun, 18 Dec 2016 07:05:33 GMT'},
          {'server', 'nginx'},
          {'content-length', '383'},
          {'content-type', 'application/json'},
          {'access-control-allow-origin', '*'},
          {'access-control-allow-credentials', 'true'}
        ],
        '{\n  "args": {}, \n  "data": "{\\"josnkey2\\":\\"jsonvalue2\\",\\"josnkey1\\":\\"jsonvalue1\\"}", \n  "files": {}, \n  "form": {}, \n  "headers": {\n    "Content-Length": "49", \n    "Content-Type": "application/json", \n    "Host": "httpbin.org"\n  }, \n  "json": {\n    "josnkey1": "jsonvalue1", \n    "josnkey2": "jsonvalue2"\n  }, \n  "origin": "183.240.20.213", \n  "url": "http://httpbin.org/post"\n}\n'}}
    end)

    assert Client.get_ip_test() |> Maxwell.Conn.get_status() == 200
  end

  test "encode decode json test" do
    :httpc
    |> stub(:request, fn _, _, _, _ ->
      {:ok,
       {{'HTTP/1.1', 200, 'OK'},
        [
          {'connection', 'keep-alive'},
          {'date', 'Sun, 18 Dec 2016 07:09:37 GMT'},
          {'server', 'nginx'},
          {'content-length', '383'},
          {'content-type', 'application/json'},
          {'access-control-allow-origin', '*'},
          {'access-control-allow-credentials', 'true'}
        ],
        '{\n  "args": {}, \n  "data": "{\\"josnkey2\\":\\"jsonvalue2\\",\\"josnkey1\\":\\"jsonvalue1\\"}", \n  "files": {}, \n  "form": {}, \n  "headers": {\n    "Content-Length": "49", \n    "Content-Type": "application/json", \n    "Host": "httpbin.org"\n  }, \n  "json": {\n    "josnkey1": "jsonvalue1", \n    "josnkey2": "jsonvalue2"\n  }, \n  "origin": "183.240.20.213", \n  "url": "http://httpbin.org/post"\n}\n'}}
    end)

    result =
      %{"josnkey1" => "jsonvalue1", "josnkey2" => "jsonvalue2"}
      |> Client.encode_decode_json_test()

    assert result == %{"josnkey1" => "jsonvalue1", "josnkey2" => "jsonvalue2"}
  end

  test "send file without content-type" do
    :httpc
    |> stub(:request, fn _, _, _, _ ->
      {:ok,
       {{'HTTP/1.1', 200, 'OK'},
        [
          {'connection', 'keep-alive'},
          {'date', 'Sun, 18 Dec 2016 07:22:05 GMT'},
          {'server', 'nginx'},
          {'content-length', '316'},
          {'content-type', 'application/json'},
          {'access-control-allow-origin', '*'},
          {'access-control-allow-credentials', 'true'}
        ],
        '{\n  "args": {}, \n  "data": "#!/usr/bin/env bash\\necho \\"test multipart file\\"\\n", \n  "files": {}, \n  "form": {}, \n  "headers": {\n    "Content-Length": "47", \n    "Content-Type": "application/x-sh", \n    "Host": "httpbin.org"\n  }, \n  "json": null, \n  "origin": "183.240.20.213", \n  "url": "http://httpbin.org/post"\n}\n'}}
    end)

    conn = Client.file_test("test/maxwell/multipart_test_file.sh")
    assert get_resp_body(conn, "data") == "#!/usr/bin/env bash\necho \"test multipart file\"\n"
  end

  test "send file with content-type" do
    :httpc
    |> stub(:request, fn _, _, _, _ ->
      {:ok,
       {{'HTTP/1.1', 200, 'OK'},
        [
          {'connection', 'keep-alive'},
          {'date', 'Sun, 18 Dec 2016 07:24:17 GMT'},
          {'server', 'nginx'},
          {'content-length', '316'},
          {'content-type', 'application/json'},
          {'access-control-allow-origin', '*'},
          {'access-control-allow-credentials', 'true'}
        ],
        '{\n  "args": {}, \n  "data": "#!/usr/bin/env bash\\necho \\"test multipart file\\"\\n", \n  "files": {}, \n  "form": {}, \n  "headers": {\n    "Content-Length": "47", \n    "Content-Type": "application/x-sh", \n    "Host": "httpbin.org"\n  }, \n  "json": null, \n  "origin": "183.240.20.213", \n  "url": "http://httpbin.org/post"\n}\n'}}
    end)

    conn = Client.file_test("test/maxwell/multipart_test_file.sh", "application/x-sh")
    assert get_resp_body(conn, "data") == "#!/usr/bin/env bash\necho \"test multipart file\"\n"
  end

  test "send stream" do
    :httpc
    |> stub(:request, fn _, _, _, _ ->
      {:ok,
       {{'HTTP/1.1', 200, 'OK'},
        [
          {'connection', 'keep-alive'},
          {'date', 'Sun, 18 Dec 2016 07:28:25 GMT'},
          {'server', 'nginx'},
          {'content-length', '283'},
          {'content-type', 'application/json'},
          {'access-control-allow-origin', '*'},
          {'access-control-allow-credentials', 'true'}
        ],
        '{\n  "args": {}, \n  "data": "112233", \n  "files": {}, \n  "form": {}, \n  "headers": {\n    "Content-Length": "6", \n    "Content-Type": "application/vnd.lotus-1-2-3", \n    "Host": "httpbin.org"\n  }, \n  "json": 112233, \n  "origin": "183.240.20.213", \n  "url": "http://httpbin.org/post"\n}\n'}}
    end)

    conn = Client.stream_test()
    assert get_resp_body(conn, "data") == "112233"
  end

  test "user-agent header test" do
    :httpc
    |> stub(:request, fn _, _, _, _ ->
      {:ok,
       {{'HTTP/1.1', 200, 'OK'},
        [
          {'connection', 'keep-alive'},
          {'date', 'Sun, 18 Dec 2016 07:30:00 GMT'},
          {'server', 'nginx'},
          {'content-length', '27'},
          {'content-type', 'application/json'},
          {'access-control-allow-origin', '*'},
          {'access-control-allow-credentials', 'true'}
        ], '{\n  "user-agent": "test"\n}\n'}}
    end)

    assert "test" |> Client.user_agent_test() == "test"
  end

  test "/put" do
    :httpc
    |> stub(:request, fn _, _, _, _ ->
      {:ok,
       {{'HTTP/1.1', 200, 'OK'},
        [
          {'connection', 'keep-alive'},
          {'date', 'Sun, 18 Dec 2016 07:30:30 GMT'},
          {'server', 'nginx'},
          {'content-length', '303'},
          {'content-type', 'application/json'},
          {'access-control-allow-origin', '*'},
          {'access-control-allow-credentials', 'true'}
        ],
        '{\n  "args": {}, \n  "data": "{\\"key\\":\\"value\\"}", \n  "files": {}, \n  "form": {}, \n  "headers": {\n    "Content-Length": "15", \n    "Content-Type": "application/json", \n    "Host": "httpbin.org"\n  }, \n  "json": {\n    "key": "value"\n  }, \n  "origin": "183.240.20.213", \n  "url": "http://httpbin.org/put"\n}\n'}}
    end)

    assert %{"key" => "value"} |> Client.put_json_test() == "{\"key\":\"value\"}"
  end

  test "/delete" do
    :httpc
    |> stub(:request, fn _, _, _, _ ->
      {:ok,
       {{'HTTP/1.1', 200, 'OK'},
        [
          {'connection', 'keep-alive'},
          {'date', 'Sun, 18 Dec 2016 07:31:04 GMT'},
          {'server', 'nginx'},
          {'content-length', '225'},
          {'content-type', 'application/json'},
          {'access-control-allow-origin', '*'},
          {'access-control-allow-credentials', 'true'}
        ],
        '{\n  "args": {}, \n  "data": "", \n  "files": {}, \n  "form": {}, \n  "headers": {\n    "Content-Length": "0", \n    "Host": "httpbin.org"\n  }, \n  "json": null, \n  "origin": "183.240.20.213", \n  "url": "http://httpbin.org/delete"\n}\n'}}
    end)

    assert Client.delete_test() == ""
  end

  test "connection refused error is normalized" do
    :httpc
    |> stub(:request, fn _, _, _, _ ->
      {:error, {:failed_connect, [{:inet, [], :econnrefused}]}}
    end)

    {:error, :econnrefused, conn} = Client.normalized_error_test()
    assert conn.state == :error
  end

  test "timeout error is normalized" do
    :httpc
    |> stub(:request, fn _, _, _, _ ->
      {:error, {:failed_connect, [{:inet, [], :timeout}]}}
    end)

    {:error, :timeout, conn} = Client.normalized_error_test()
    assert conn.state == :error
  end

  test "unrecognized connection failed error is normalized" do
    :httpc
    |> stub(:request, fn _, _, _, _ ->
      {:error, {:failed_connect, [{:tcp, [], :i_made_this_up}]}}
    end)

    {:error, {:failed_connect, [{:tcp, [], :i_made_this_up}]}, conn} =
      Client.normalized_error_test()

    assert conn.state == :error
  end

  test "internal error is normalized" do
    :httpc
    |> stub(:request, fn _, _, _, _ ->
      {:error, :internal}
    end)

    {:error, :internal, conn} = Client.normalized_error_test()
    assert conn.state == :error
  end

  test "adapter return error" do
    :httpc
    |> stub(:request, fn _, _, _, _ ->
      {:error, :timeout}
    end)

    {:error, :timeout, conn} = Client.timeout_test()
    assert conn.state == :error
  end
end
