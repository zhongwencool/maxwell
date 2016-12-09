defmodule Maxwell do
  @moduledoc  """
  The maxwell specification.

  There are two kind of usages: Basic Usage and Advanced Middleware Usage.

  ### Basic Usage

      ## Returns Origin IP, for example %{"origin" => "127.0.0.1"}
      Maxwell.Conn.new
      |> Maxwell.Conn.put_url("http://httpbin.org/ip")
      |> Maxwell.get!
      |> Maxwell.Conn.get_resp_body
      |> Poison.decode!

  Find all `get_*&put_*` helper functions by `h Maxwell.Conn.xxx`

  ### Advanced Middleware Usage(Create API Client).

         defmodule Client do
           use Maxwell.Builder, ~w(get)a
           adapter Maxwell.Adapter.Ibrowse

           middleware Maxwell.Middleware.BaseUrl,   "http://httpbin.org"
           middleware Maxwell.Middleware.Opts,      [connect_timeout: 1000]
           middleware Maxwell.Middleware.Headers,   %{'User-Agent' => "zhongwencool"}
           middleware Maxwell.Middleware.Json

           ## Returns origin IP, for example "127.0.0.1"
           def ip do
             new()
             |> put_path("ip")
             |> get!()
             |> get_resp_body("origin")
           end

           ## Generates n random bytes of binary data, accepts optional seed integer parameter
           def get_random_bytes(size) do
             "/bytes/\#\{size\}"
             |> put_path
             |> get!
             |> get_resp_body(&to_string/1)
           end
        end

  """
  use Maxwell.Builder

end

