defmodule Maxwell.Middleware.Proxy do
  @moduledoc  """
  Manage Proxy for adapter

  ### Examples

        # Client.ex
        use Maxwell.Builder ~(get)a
        @middleware Maxwell.Middleware.Proxy %{'User-Agent' => "zhongwencool"}

        def request do
        # headers is merge to %{'User-Agent' => "zhongwencool", 'username' => "zhongwencool"}
          %{'username' => "zhongwencool"} |> put_req_header |> get!
        end

  """

  @proxy_options ~w(host port user passwd)a

  use Maxwell.Middleware

  def init(proxy) do
    check_options(proxy)
    fetch_proxy_options(proxy)
  end

  def request(conn, proxy) do
    %{conn| opts: Keyword.merge(proxy, conn.opts)}
  end

  defp check_options(options) do
    case Enum.all?(options, fn({key, _value}) -> Enum.member?(@proxy_options, key) end) do
      true -> :ok
      false -> raise(ArgumentError, "proxy options key only accpect #{inspect @proxy_options} but got: #{inspect options}");
    end
  end

  defp fetch_proxy_options(options) do
    case Keyword.fetch(options, :host) do
      {:ok, host}->
        host = host |> to_string
        port = options |> Keyword.get(:port) |> to_string
        case Keyword.fetch(options, :user) do
          {:ok, user} ->
            passwd = options |> Keyword.get(:passwd) |> to_string
            [{:proxy, {host, port}}, {:proxy_auth, user, passwd}]
          :error ->
            [{:proxy, {host, port}}]
        end
      :error ->
        options
    end
  end

end

