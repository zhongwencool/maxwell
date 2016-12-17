defmodule Maxwell.IbrowseTest do
  use ExUnit.Case
  import Maxwell.Conn

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

  setup do
    :random.seed(:erlang.phash2([node()]), :erlang.monotonic_time, :erlang.unique_integer)
    {:ok, _} = Application.ensure_all_started(:ibrowse)
    :ok
  end

  test "sync request" do
    assert Client.get_ip_test |> Maxwell.Conn.get_status == 200
  end

  test "encode decode json test" do
    result = %{"josnkey1" => "jsonvalue1", "josnkey2" => "jsonvalue2"} |> Client.encode_decode_json_test
    assert result == %{"josnkey1" => "jsonvalue1", "josnkey2" => "jsonvalue2"}

  end

  test "mutilpart body file" do
    conn = Client.multipart_test
    assert get_resp_body(conn, "files") == %{"file" => "#!/usr/bin/env bash\necho \"test multipart file\"\n"}
  end

  test "mutilpart body file extra headers" do
    conn = Client.multipart_with_extra_header_test
    assert get_resp_body(conn, "files") == %{"file" => "#!/usr/bin/env bash\necho \"test multipart file\"\n"}
  end

  test "send file without content-type" do
    conn = Client.file_test("test/maxwell/multipart_test_file.sh")
    assert get_resp_body(conn, "data") == "#!/usr/bin/env bash\necho \"test multipart file\"\n"
  end

  test "send file with content-type" do
    conn = Client.file_test("test/maxwell/multipart_test_file.sh", "application/x-sh")
    assert get_resp_body(conn, "data") == "#!/usr/bin/env bash\necho \"test multipart file\"\n"
  end

  test "send stream" do
    conn = Client.stream_test
    assert get_resp_body(conn, "data") == "112233"
  end

  test "user-agent header test" do
    assert "test" |> Client.user_agent_test == "test"
  end

  test "/put" do
    assert %{"key" => "value"} |> Client.put_json_test == "{\"key\":\"value\"}"
  end

  test "/delete" do
    assert Client.delete_test == ""
  end

  test "adapter return error" do
    {:error, :req_timedout, conn} = Client.timeout_test
    assert conn.state == :error
  end

end

