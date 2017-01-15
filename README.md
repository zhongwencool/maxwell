# Maxwell

[![Build Status](https://travis-ci.org/zhongwencool/maxwell.svg?branch=master)](https://travis-ci.org/zhongwencool/maxwell)
[![Inline docs](http://inch-ci.org/github/zhongwencool/maxwell.svg)](http://inch-ci.org/github/zhongwencool/maxwell)
[![Coveralls Coverage](https://img.shields.io/coveralls/zhongwencool/maxwell.svg)](https://coveralls.io/github/zhongwencool/maxwell)
[![Hex.pm](https://img.shields.io/hexpm/v/maxwell.svg)](http://hex.pm/packages/maxwell)

Maxwell is an HTTP client that provides a common interface over [:httpc](http://erlang.org/doc/man/httpc.html), [:ibrowse](https://github.com/cmullaparthi/ibrowse), [:hackney](https://github.com/benoitc/hackney).

[Documentation for Maxwell is available online](https://hexdocs.pm/maxwell).

## Usage

Use `Maxwell.Builder` module to create the API wrappers. The following is a simple example:

```elixir
defmodule GitHubClient do
  # Generates `get/1`, `get!/1`, `patch/1`, `patch!/1` public functions
  # You can omit the list and functions for all HTTP methods will be generated
  use Maxwell.Builder, ~w(get patch)a

  middleware Maxwell.Middleware.BaseUrl, "https://api.github.com"
  middleware Maxwell.Middleware.Headers, %{'Content-Type': "application/vnd.github.v3+json", 'User-Agent': 'zhongwenool'}
  middleware Maxwell.Middleware.Opts, [connect_timeout: 3000]
  middleware Maxwell.Middleware.Json
  middleware Maxwell.Middleware.Logger

  adapter Maxwell.Adapter.Hackney # default adapter is Maxwell.Adapter.Httpc

  # List public repositories for the specified user.
  def user_repos(username) do
    put_path("/users/" <> username <> "/repos") |> get
  end

  # Edit owner repositories
  def edit_repo_desc(owner, repo, name, desc) do
    new
    |> put_path("/repos/#{owner}/#{repo}")
    |> put_req_body(%{name: name, description: desc})
    |> patch
  end
end
```

Example usage is as follows:

```elixir
$ MIX_ENV=TEST iex -S mix
iex(1)> GitHubClient.
edit_repo_desc/4    get!/0              get!/1
get!/2              get/0               get/1
patch!/0            patch!/1            patch!/2
patch/0             patch/1             user_repos/1
iex(1)> GitHubClient.user_repos("zhongwencool")
22:23:42.307 [info]  get https://api.github.com <<<200(3085.772ms)
%Maxwell.Conn{method: :get, opts: [connect_timeout: 3000, recv_timeout: 20000]
...(truncated)
```

You can also use Maxwell without defining a module:

```elixir
iex(1)> alias Maxwell.Conn
iex(2)> Conn.new("http://httpbin.org") |>
    Conn.put_path("/drip") |> 
    Conn.put_query_string(%{numbytes: 25, duration: 1, delay: 1, code: 200}) |> 
    Maxwell.get
{:ok,
 %Maxwell.Conn{method: :get, opts: [], path: "",
  query_string: %{code: 200, delay: 1, duration: 1, numbytes: 25},
  req_body: nil, req_headers: %{}, resp_body: '*************************',
  resp_headers: %{"access-control-allow-credentials" => {"access-control-allow-credentials",
     "true"},
    "access-control-allow-origin" => {"access-control-allow-origin", "*"},
    "connection" => {"connection", "keep-alive"},
    "content-length" => {"content-length", "25"},
    "content-type" => {"content-type", "application/octet-stream"},
    "date" => {"date", "Sun, 18 Dec 2016 14:32:38 GMT"},
    "server" => {"server", "nginx"}}, state: :sent, status: 200,
  url: "http://httpbin.org/drip"}}
```

### Helper functions for Maxwell.Conn

```elixir
new(request_url_string)
|> put_query_string(request_query_map)
|> put_req_header(request_headers_map)
|> put_option(request_opts_keyword_list)
|> put_req_body(request_body_term)
|> YourClient.{http_method}!
|> get_resp_body
```

See the documentation of `Maxwell.Conn` for more information.

## Responses

When calling one of (non-bang versions) of the HTTP method functions on a client module or the `Maxwell` module, you
can expect either `{:ok, Maxwell.Conn.t}` or `{:error, reason, Maxwell.Conn.t}` to be returned.

When calling of the bang versions of the HTTP method functions, e.g. `get!`, you can expect `Maxwell.Conn.t` if successful,
or a `Maxwell.Error` will be raised.

## Example Client

The following is a full implementation of a client showing various features of Maxwell.

```elixir
defmodule Client do
  #generate 4 function get/1, get!/1 post/1 post!/1 function
  use Maxwell.Builder, ~w(get post)a

  middleware Maxwell.Middleware.BaseUrl, "http://httpbin.org"
  middleware Maxwell.Middleware.Headers, %{"Content-Type" => "application/json"}
  middleware Maxwell.Middleware.Opts, [connect_timeout: 5000, recv_timeout: 10000]
  middleware Maxwell.Middleware.Json
  middleware Maxwell.Middleware.Logger

  adapter Maxwell.Adapter.Hackney

  @doc """
  Simple get request
  Get origin ip
  """
  def get_ip() do
    new
    |> put_path("/ip")
    |> get!
    |> get_resp_body("origin")
  end

  @doc """
  Post whole file once
  ###Example
     Client.post_file_once("./mix.exs")
  """
  def post_file_once(filepath) do
    new
    |> put_path("/post")
    |> put_req_body({:file, filepath})
    |> post!
    |> get_resp_body("data")
  end

  @doc """
  Post whole file by chunked
  ###Example
     Client.post_file_chunked("./mix.exs")
  """
  def post_file_chunked(filepath) do
    new
    |> put_path("/post")
    |> put_req_header("transfer_encoding", "chunked")
    |> put_req_body({:file, filepath})
    |> post!
    |> get_resp_body("data")
  end

  @doc """
  Post by stream
  ###Example
     ["1", "2", "3"] |> Stream.map(fn(x) -> List.duplicate(x, 2) end) |> Client.post_stream
  """
  def post_stream(stream) do
    new
    |> put_path("/post")
    |> put_req_body(stream)
    |> post!
    |> get_resp_body("data")
  end

  @doc """
  Post multipart form
  ###Example
    Client.post_multipart_form({:multipart, [{:file, "./mix.exs"}]})
  """
  def post_multipart_form(multipart) do
    new
    |> put_path("/post")
    |> put_req_body(multipart)
    |> post!
    |> get_resp_body("data")
  end

end

```

## Installation

  1. Add maxwell to your list of dependencies in `mix.exs`:
```ex
   def deps do
     [{:maxwell, "~> 2.1.0"}]
   end
```
  2. Ensure maxwell has started before your application:
```ex
   def application do
      [applications: [:maxwell]] # also add your adapter(ibrowse, hackney)
   end
```

## Adapters

Maxwell has support for different adapters that do the actual HTTP request processing.

### httpc

Maxwell has built-in support for the [httpc](http://erlang.org/doc/man/httpc.html) Erlang HTTP client.

To use it simply place `adapter Maxwell.Adapter.Httpc` in your API client definition, or by
setting the global default adapter, as shown below:

```ex
config :maxwell,
  default_adapter: Maxwell.Adapter.Httpc
```

**NOTE**: Remember to include `:ibrowse` in your applications list.

### ibrowse

Maxwell has built-in support for the [ibrowse](https://github.com/cmullaparthi/ibrowse) Erlang HTTP client.

To use it simply place `adapter Maxwell.Adapter.Ibrowse` in your API client definition, or by
setting the global default adapter, as shown previously.

**NOTE**: Remember to include `:ibrowse` in your applications list.

### hackney

Maxwell has built-in support for the [hackney](https://github.com/benoitc/hackney) Erlang HTTP client.

To use it simply place `adapter Maxwell.Adapter.Hackney` in your API client definition, or by
setting the global default adapter, as shown previously.

**NOTE**: Remember to include `:hackney` in your applications list.

## Built-in Middleware

### Maxwell.Middleware.BaseUrl

Sets the base url for all requests.

### Maxwell.Middleware.Headers

Sets default headers for all requests.

### Maxwell.Middleware.Opts

Sets adapter options for all requests.

### Maxwell.Middleware.Rels

Decodes rel links in the response, and places them in the `:rels` key of the `Maxwell.Conn` struct.

### Maxwell.Middleware.Logger

Logs information about all requests and responses. You can set `:log_level` to log the information at that level.

### Maxwell.Middleware.Json

Encodes all requests as `application/json` and decodes all responses as `application/json`.

### Maxwell.Middleware.EncodeJson

Encodes all requests as `application/json`.

### Maxwell.Middleware.DecodeJson

Decodes all responses as `application/json`.

**NOTE**: The `*Json` middlewares require [Poison](https://github.com/devinus/poison) as dependency, versions 2.x and 3.x are supported.
You may provide your own encoder/decoder by providing the following options:

```ex
# For the EncodeJson module
middleware Maxwell.Middleware.EncodeJson, 
  encode_content_type: "text/javascript", 
  encode_func: &other_json_lib.encode/1]

# For the DecodeJson module
middleware Maxwell.Middleware.DecodeJson, 
  decode_content_types: ["yourowntype"], 
  decode_func: &other_json_lib.decode/1]

# Both sets of options can be provided to the Json module
```

## Custom Middlewares

Take a look at the [Maxwell.Middleware](https://github.com/zhongwencool/maxwell/blob/master/lib/maxwell/middleware/middleware.ex) for more information
on the behaviour. For example implementations take a look at any of the middleware modules in the repository.

## Contributing

Contributions are more than welcome!

Check the issues tracker for anything marked "help wanted", and post a comment that you are planning to begin working on the issue. We can
then provide guidance on implementation if necessary.

## License

See the [LICENSE](https://github.com/zhongwencool/maxwell/blob/master/LICENSE) file for license rights and limitations (MIT).

