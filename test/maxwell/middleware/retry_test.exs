defmodule RetryTest do
  use ExUnit.Case, async: false
  alias Maxwell.Conn

  defmodule LaggyAdapter do
    def start_link, do: Agent.start_link(fn -> 0 end, name: __MODULE__)

    def call(%{path: path} = conn) do
      conn = %{conn | state: :sent}
      Agent.get_and_update __MODULE__, fn retries ->
        response = case path do
          "/ok"                     -> %{conn | status: 200, resp_body: "ok"}
          "/maybe" when retries < 5 -> {:error, :econnrefused, conn}
          "/maybe"                  -> %{conn | status: 200, resp_body: "maybe"}
          "/nope"                   -> {:error, :econnrefused, conn}
          "/boom"                   -> {:error, :boom, conn}
        end

        {response, retries + 1}
      end
    end
  end


  defmodule Client do
    use Maxwell.Builder

    middleware Maxwell.Middleware.Retry, delay: 10, max_retries: 10

    adapter LaggyAdapter
  end

  setup do
    {:ok, _} = LaggyAdapter.start_link
    :ok
  end

  test "pass on successful request" do
    assert Conn.new("/ok") |> Client.get! |> Conn.get_resp_body() == "ok"
  end

  test "pass after retry" do
    assert Conn.new("/maybe") |> Client.get! |> Conn.get_resp_body() == "maybe"
  end

  test "raise error if max_retries is exceeded" do
    assert_raise Maxwell.Error, fn -> Conn.new("/nope") |> Client.get! end
  end

  test "raise error if error other than econnrefused occurs" do
    assert_raise Maxwell.Error, fn -> Conn.new("/boom") |> Client.get! end
  end

end
