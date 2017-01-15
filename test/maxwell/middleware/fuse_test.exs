defmodule FuseTest do
  use ExUnit.Case, async: false
  alias Maxwell.Conn

  defmodule FuseAdapter do
    def call(%{path: path} = conn) do
      send self(), :request_made
      conn = %{conn | state: :sent}
      case path do
        "/ok" -> %{conn | status: 200, resp_body: "ok"}
        "/unavailable" -> {:error, :econnrefused, conn}
      end
    end
  end

  defmodule Client do
    use Maxwell.Builder
    middleware Maxwell.Middleware.Fuse,
      name: __MODULE__,
      fuse_opts: {{:standard, 2, 10_000}, {:reset, 60_000}}
    adapter FuseAdapter
  end


  setup do
    {:ok, _} = Application.ensure_all_started(:fuse)
    :fuse.reset(Client)
    :ok
  end

  test "regular endpoint" do
    assert Conn.put_path("/ok") |> Client.get! |> Conn.get_resp_body() == "ok"
  end

  test "unavailable endpoint" do
    assert_raise Maxwell.Error, fn -> Conn.put_path("/unavailable") |> Client.get! end
    assert_receive :request_made
    assert_raise Maxwell.Error, fn -> Conn.put_path("/unavailable") |> Client.get! end
    assert_receive :request_made
    assert_raise Maxwell.Error, fn -> Conn.put_path("/unavailable") |> Client.get! end
    assert_receive :request_made

    assert_raise Maxwell.Error, fn -> Conn.put_path("/unavailable") |> Client.get! end
    refute_receive :request_made
    assert_raise Maxwell.Error, fn -> Conn.put_path("/unavailable") |> Client.get! end
    refute_receive :request_made
  end
end
