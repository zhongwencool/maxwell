defmodule Maxwell do
  @moduledoc  """
  The maxwell specification.

  There are two kind of usages: basic usage and advanced middleware usage.

  ### Basic Usage

      ## Returns Origin IP, for example %{"origin" => "127.0.0.1"}
      "http://httpbin.org/ip"
      |> Maxwell.Conn.new()
      |> Maxwell.get!()
      |> Maxwell.Conn.get_resp_body()
      |> Poison.decode!()

  Find all `get_*&put_*` helper functions by `h Maxwell.Conn.xxx`

  ### Advanced Middleware Usage(Create API Client).

         defmodule Client do
           use Maxwell.Builder, ~w(get)a
           adapter Maxwell.Adapter.Ibrowse

           middleware Maxwell.Middleware.BaseUrl,   "http://httpbin.org"
           middleware Maxwell.Middleware.Opts,      [connect_timeout: 5000]
           middleware Maxwell.Middleware.Headers,   %{"User-Agent" => "zhongwencool"}
           middleware Maxwell.Middleware.Json

           ## Returns origin IP, for example "127.0.0.1"
           def ip() do
             "/ip"
             |> new()
             |> get!()
             |> get_resp_body("origin")
           end

           ## Generates n random bytes of binary data, accepts optional seed integer parameter
           def get_random_bytes(size) do
             "/bytes/\#\{size\}"
             |> new()
             |> get!()
             |> get_resp_body(&to_string/1)
           end
        end

  """
  use Maxwell.Builder

end

