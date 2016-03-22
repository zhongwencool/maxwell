defmodule IbrowseTest do
  use ExUnit.Case

  defmodule Client do
    use Maxwell.Builder
    middleware Maxwell.Middleware.BaseUrl, "http://httpbin.org"
    middleware Maxwell.Middleware.Opts, [connect_timeout: 3000]

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

  test "async requests" do
    {:ok, _id} = Client.get(url: "/ip", opts: [respond_to: self])

    assert_receive {:tesla_response, _}, 2000
  end

  test "async requests parameters" do
    {:ok, _id} = Client.get(url: "http://httpbin.org/ip", opts: [respond_to: self])

    receive do
      {:tesla_response, res} ->
        assert res.status == 200
    after
      5000 -> raise "Timeout"
    end
  end

end
