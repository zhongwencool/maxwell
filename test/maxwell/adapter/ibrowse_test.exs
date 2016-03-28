defmodule Maxwell.IbrowseTest do
  use ExUnit.Case

  defmodule Client do
    use Maxwell.Builder
    middleware Maxwell.Middleware.BaseUrl, "http://httpbin.org"
    middleware Maxwell.Middleware.Opts, [connect_timeout: 5000]
    middleware Maxwell.Middleware.EncodeJson
    middleware Maxwell.Middleware.DecodeJson

    adapter Maxwell.Adapter.Ibrowse
  end

  setup do
    :random.seed(:erlang.phash2([node()]), :erlang.monotonic_time, :erlang.unique_integer)
    Application.ensure_started(:ibrowse)
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
        assert is_list(res.body) == true
    after
      5500 -> raise "Timeout"
    end
  end

  test "mutilpart body" do
    data =
      [url: "/post", multipart: [{"name", "value"}, {:file, "test/maxwell/multipart_test_file.sh"}]]
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

end
