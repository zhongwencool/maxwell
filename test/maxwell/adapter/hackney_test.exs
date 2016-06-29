defmodule Maxwell.HackneyTest do
  use ExUnit.Case

  defmodule Client do
    use Maxwell.Builder
    middleware Maxwell.Middleware.BaseUrl, "http://httpbin.org"
    middleware Maxwell.Middleware.Opts, [connect_timeout: 6000]

    middleware Maxwell.Middleware.EncodeJson
    middleware Maxwell.Middleware.DecodeJson

    adapter Maxwell.Adapter.Hackney
  end

  setup do
    :random.seed(:erlang.phash2([node()]), :erlang.monotonic_time, :erlang.unique_integer)
    {:ok, _} = Application.ensure_all_started(:hackney)
    :ok
  end

  test "sync request" do
    {:ok, reponse} = Client.get(url: "/ip")
    assert reponse.status == 200
  end

  test "encode decode json" do
    {:ok, res} = Client.post(url: "/post",
                            body: %{"josnkey1" => "jsonvalue1", "josnkey2" => "jsonvalue2"})
    assert res.body["json"] == %{"josnkey1" => "jsonvalue1", "josnkey2" => "jsonvalue2"}

  end

  # Streams n random bytes of binary data, accepts optional seed and chunk_size integer parameters.
  test "async requests stream" do
    {:ok, _id} = Client.get(url: "http://httpbin.org/stream-bytes/1000", opts: [respond_to: self])

    receive do
      {:maxwell_response, {:ok, res}} ->
        assert is_binary(res.body) == true
    after
      5500 -> raise "Timeout"
    end
  end

  test "mutilpart body file" do
    data =
      [url: "/post", multipart: [{"name", "value"}, {:file, "test/maxwell/multipart_test_file.sh"}]]
      |> Client.post!

    assert data.body["files"] == %{"file" => "#!/usr/bin/env bash\necho \"test multipart file\"\n"}

  end

  test "mutilpart body file extra headers" do
    data =
      [url: "/post", multipart: [{"name", "value"}, {:file, "test/maxwell/multipart_test_file.sh", [{"Content-Type", "image/jpeg"}]}]]
      |> Client.post!

    assert data.body["files"] == %{"file" => "#!/usr/bin/env bash\necho \"test multipart file\"\n"}

  end

  test "user-agent header" do
    data =
     [url: "/user-agent", headers: %{"user-agent" => "test"}]
     |> Client.get!

     assert data.body["user-agent"] == "test"
  end

  test "/put" do
    data =
     [url: "/put", body: %{"key" => "value"}]
     |> Client.put!

     assert data.body["data"] == "{\"key\":\"value\"}"
  end

  test "/delete" do
    data =
     [url: "/delete", body: %{"key" => "value"}]
     |> Client.delete!
     assert data.body["data"] == ""
  end

  test "http url connect timeout" do
    data =
     [url: "notexist", opts: [connect_timeout: 1000]]
     |> Client.get
    assert data == {:error, :connect_timeout}
  end

  test "Head without body(test hackney.ex return {:ok, status, header})" do
     data = Client.head!
     assert data.body == ""
  end

end
