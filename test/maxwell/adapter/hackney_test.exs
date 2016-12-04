defmodule Maxwell.HackneyTest do
  use ExUnit.Case

  defmodule Client do
    use Maxwell.Builder
    middleware Maxwell.Middleware.BaseUrl, "http://httpbin.org"
    middleware Maxwell.Middleware.Opts, [connect_timeout: 6000]

    middleware Maxwell.Middleware.Json

    adapter Maxwell.Adapter.Hackney

    def get_ip do
      put_path("/ip")
      |> get!
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
    {:ok, _} = Application.ensure_all_started(:hackney)
    :ok
  end

  alias Maxwell.Conn
  test "sync request" do
    assert Client.get_ip |> Conn.get_status == 200
  end

  test "encode decode json" do
    res = Client.encode_decode_json(%{"josnkey1" => "jsonvalue1", "josnkey2" => "jsonvalue2"})
    assert res == %{"josnkey1" => "jsonvalue1", "josnkey2" => "jsonvalue2"}

  end

  # Streams n random bytes of binary data, accepts optional seed and chunk_size integer parameters.
  #test "async requests stream" do
  #  {:ok, _id} = Client.get(url: "http://httpbin.org/stream-bytes/1000", opts: [respond_to: self])

  #  receive do
  #    {:maxwell_response, {:ok, res}} ->
  #      assert is_binary(res.body) == true
  #  after
  #    5500 -> raise "Timeout"
  #  end
  #end

  #test "mutilpart body file" do
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

  test "http url not exist" do
    {:error, :nxdomain, conn} =
      "notexist"
      |> Maxwell.Conn.put_path
      |> Maxwell.Conn.put_option(:connect_timeout, 10000)
      |> Client.get
    assert conn.state == :error
  end

  test "Head without body(test hackney.ex return {:ok, status, header})" do
     data = Client.head!
     assert data.resp_body == ""
  end

end

