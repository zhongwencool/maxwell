defmodule Maxwell.HackneyTest do
  use ExUnit.Case

  defmodule Client do
    use Maxwell.Builder
    middleware Maxwell.Middleware.BaseUrl, "http://httpbin.org"
    middleware Maxwell.Middleware.Opts, [connect_timeout: 6000]

    adapter Maxwell.Adapter.Hackney
  end

  setup do
    Application.ensure_started(:hackney)
    :ok
  end

  test "sync request" do
    {:ok, reponse} = Client.get(url: "/ip")
    assert reponse.status == 200
  end

  test "async requests" do
    {:ok, _id} = Client.get(url: "/ip", opts: [respond_to: self])

    assert_receive {:maxwell_response, _}, 4000
  end

  test "async requests parameters" do
    {:ok, _id} = Client.get(url: "http://httpbin.org/ip", opts: [respond_to: self])

    receive do
      {:maxwell_response, res} ->
        assert res != nil
    after
      5500 -> raise "Timeout"
    end
  end

end