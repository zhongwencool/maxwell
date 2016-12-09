defmodule Maxwell.IbrowseTest do
  use ExUnit.Case

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

  # Streams n random bytes of binary data, accepts optional seed and chunk_size integer parameters.
  # test "async requests stream" do
  #  {:ok, _id} = Client.get(url: "http://httpbin.org/stream-bytes/1000", opts: [respond_to: self])

  #  receive do
  #    {:maxwell_response, {:ok, res}} ->
  #      assert is_list(res.body) == true
  #  after
  #    5500 -> raise "Timeout"
  #  end
  #end

  #test "mutilpart body" do
  #  data =
  #    [url: "/post", multipart: [{"name", "value"}, {:file, "test/maxwell/multipart_test_file.sh"}]]
  #    |> Client.post!

  #  assert data.body["files"] == %{"file" => "#!/usr/bin/env bash\necho \"test multipart file\"\n"}

  # end

  # test "mutilpart body file extra headers" do
  #  data =
  #    [url: "/post", multipart: [{"name", "value"}, {:file, "test/maxwell/multipart_test_file.sh", [{"Content-Type", "image/jpeg"}]}]]
  #    |> Client.post!

  #  assert data.body["files"] == %{"file" => "#!/usr/bin/env bash\necho \"test multipart file\"\n"}

  # end

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

