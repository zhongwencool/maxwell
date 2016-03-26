defmodule Maxwell.IbrowseTest do
  use ExUnit.Case

  defmodule Client do
    use Maxwell.Builder
    middleware Maxwell.Middleware.BaseUrl, "http://httpbin.org"
    middleware Maxwell.Middleware.Opts, [connect_timeout: 3000]
    middleware Maxwell.Middleware.EncodeJson
    middleware Maxwell.Middleware.DecodeJson

    adapter Maxwell.Adapter.Ibrowse
  end

  setup do
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

end
