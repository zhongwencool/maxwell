defmodule Maxwell.IbrowseTest do
  use ExUnit.Case

  defmodule Client do
    use Maxwell.Builder
    middleware Maxwell.Middleware.BaseUrl, "http://httpbin.org"
    middleware Maxwell.Middleware.Opts, [connect_timeout: 5000]
    middleware Maxwell.Middleware.Json

    def get_ip() do
      "/ip" |> put_path |> Client.get!
    end

    def encode_decode_json(body) do
      "/post"
      |> put_path
      |> put_req_body(body)
      |> post!
      |> get_resp_body("json")
    end

    def user_agent(user_agent) do
      "/user-agent"
      |> put_path
      |> put_req_header("user-agent", user_agent)
      |> get!
      |> get_resp_body("user-agent")
    end

    def put_json(json) do
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

  end

  setup do
    :random.seed(:erlang.phash2([node()]), :erlang.monotonic_time, :erlang.unique_integer)
    {:ok, _} = Application.ensure_all_started(:ibrowse)
    :ok
  end

  test "sync request" do
    reponse = Client.get_ip
    assert Maxwell.Conn.get_status(reponse) == 200
  end

  test "encode decode json" do
    result = Client.encode_decode_json(%{"josnkey1" => "jsonvalue1", "josnkey2" => "jsonvalue2"})
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

  test "user-agent header" do
    assert Client.user_agent("test") == "test"
  end

  test "/put" do
    assert Client.put_json(%{"key" => "value"}) == "{\"key\":\"value\"}"
  end

  test "/delete" do
    assert Client.delete_test() == ""
  end

end

