# Maxwell

[![Build Status](https://travis-ci.org/zhongwencool/maxwell.svg?branch=master)](https://travis-ci.org/zhongwencool/maxwell)
[![Inline docs](http://inch-ci.org/github/zhongwencool/maxwell.svg)](http://inch-ci.org/github/zhongwencool/maxwell)
[![Coveralls Coverage](https://img.shields.io/coveralls/zhongwencool/maxwell.svg)](https://coveralls.io/github/zhongwencool/maxwell)
[![Hex.pm](https://img.shields.io/hexpm/v/maxwell.svg)](http://hex.pm/packages/maxwell)

Maxwell is an HTTP client that provides a common interface over [:httpc](http://erlang.org/doc/man/httpc.html), [:ibrowse](https://github.com/cmullaparthi/ibrowse), [:hackney](https://github.com/benoitc/hackney).

[Documentation for Maxwell is available online](https://hexdocs.pm/maxwell).

## Usage

Use `Maxwell.Builder` module to create the API wrappers.

```ex
defmodule GitHubClient do
  #generate 4 function get/1, get!/1 patch/1 patch!/1 function
  use Maxwell.Builder, ~w(get patch)a

  middleware Maxwell.Middleware.BaseUrl, "https://api.github.com"
  middleware Maxwell.Middleware.Headers, %{'Content-Type': "application/vnd.github.v3+json", 'User-Agent': 'zhongwenool'}
  middleware Maxwell.Middleware.Opts, [connect_timeout: 3000]
  middleware Maxwell.Middleware.Json
  middleware Maxwell.Middleware.Logger

  adapter Maxwell.Adapter.Hackney # default adapter is Maxwell.Adapter.Httpc

  #List public repositories for the specified user.
  #:hackney.request(:get,
  #                'https://api.github.com/users/zhongwencool/repos',
  #                ['Content-Type': "application/vnd.github.v3+json", 'User-Agent': 'zhongwenool'],
  #                [],
  #                [connect_timeout: 3000])
  def user_repos(username) do
    put_path("/users/" <> username <> "/repos") |> get
  end

  # Edit owner repositories
  # :hackney.request(:patch,
  #                  'https://api.github.com/repos/owner/repo',
  #                  ['Content-Type': "application/vnd.github.v3+json", 'User-Agent': 'zhongwenool'],
  #                  "{\"name\":\"name\",\"description\":\"desc\"}",
  #                  [connect_timeout: 3000])
  def edit_repo_desc(owner, repo, name, desc) do
    new
    |> put_path("/repos/#{owner}/#{repo}")
    |> put_req_body(%{name: name, description: desc})
    |> patch
  end
end
```
```ex
MIX_ENV=TEST iex -S mix
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
if you don't want to defined a client module:
```ex
iex(2)> Maxwell.Conn.new("http://httpbin.org/drip") |> Maxwell.Conn.put_query_string(%{numbytes: 25, duration: 1, delay: 1, code: 200}) |> Maxwell.get
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
### Maxwell.Conn helper functions
```ex
  new(request_url_string)
  |> put_query_string(request_query_map)
  |> put_req_header(request_headers_map)
  |> put_option(request_opts_keyword_list)
  |> put_req_body(request_body_term)
  |> YourClient.{http_method}!
  |> get_resp_body
```
For more examples see `h Maxwell.Conn.XXX`

## Response result
```ex
{:ok,
  %Maxwell{
    resp_headers: reponse_headers_map,
    status:  reponse_http_status_integer,
    resp_body:    reponse_body_term,
    url:     request_urlwithquery_string,
  }}

# or
{:error, reason_term, conn}

```

## Request Examples
```ex
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
      [applications: [:maxwell]] # **also add your adapter(ibrowse,hackney) here **
   end
```
## Adapters

Maxwell has support for different adapters that do the actual HTTP request processing.

### httpc

Maxwell has built-in support for [httpc](http://erlang.org/doc/man/httpc.html) Erlang HTTP client.

To use it simply include `adapter Maxwell.Adapter.Httpc` line in your API client definition.
Setting global default adapter

```ex
config :maxwell,
  default_adapter: Maxwell.Adapter.Httpc
```

### ibrowse

Maxwell has built-in support for [ibrowse](https://github.com/cmullaparthi/ibrowse) Erlang HTTP client.

To use it simply include `adapter Maxwell.Adapter.Ibrowse` line in your API client definition.
Setting global default adapter

```ex
config :maxwell,
  default_adapter: Maxwell.Adapter.Ibrowse
```

NOTE: Remember to include `:ibrowse` in applications list.
### hackney

Maxwell has built-in support for [hackney](https://github.com/benoitc/hackney) Erlang HTTP client.

To use it simply include `adapter Maxwell.Adapter.Hackney` line in your API client definition.
Setting global default adapter

```ex
config :maxwell,
  default_adapter: Maxwell.Adapter.Hackney
```

NOTE: Remember to include `:hackney` in applications list.

## Available Middleware
- [Maxwell.Middleware.BaseUrl](https://github.com/zhongwencool/maxwell/blob/master/lib/maxwell/middleware/baseurl.ex) - set base url for all request
- [Maxwell.Middleware.Headers](https://github.com/zhongwencool/maxwell/blob/master/lib/maxwell/middleware/header.ex) - set request headers
- [Maxwell.Middleware.Opts](https://github.com/zhongwencool/maxwell/blob/master/lib/maxwell/middleware/opts.ex) - set options for all request
- [Maxwell.Middleware.Rels](https://github.com/zhongwencool/maxwell/blob/master/lib/maxwell/middleware/rels.ex) - decode reponse rels
- [Maxwell.Middleware.Logger](https://github.com/zhongwencool/maxwell/blob/master/lib/maxwell/middleware/logger.ex) - Logger your request and response
- [Maxwell.Middleware.Json](https://github.com/zhongwencool/maxwell/blob/master/lib/maxwell/middleware/json.ex) - encode/decode body made up by EncodeJson and DecodeJson
- [Maxwell.Middleware.EncodeJson](https://github.com/zhongwencool/maxwell/blob/master/lib/maxwell/middleware/json.ex) - encdode request body as JSON, it will add 'Content-Type' to headers
- [Maxwell.Middleware.DecodeJson](https://github.com/zhongwencool/maxwell/blob/master/lib/maxwell/middleware/json.ex) - decode response body as JSON
NOTE: Default requires [poison](https://github.com/devinus/poison) as dependency

```ex
@middleware Maxwell.Middleware.EncodeJson, [encode_content_type: "text/javascript", encode_func: &other_json_lib.encode/1]
@middleware Maxwell.Middleware.DecodeJson, [decode_content_types: ["yourowntype"], decode_func: &other_json_lib.decode/1]
```
See more by `h Maxwell.Middleware.{name}`

## Writing your own middleware

See [Maxwell.Middleware.BaseUrl](https://github.com/zhongwencool/maxwell/blob/master/lib/maxwell/middleware/baseurl.ex) and [Maxwell.Middleware.DecodeJson](https://github.com/zhongwencool/maxwell/blob/master/lib/maxwell/middleware/json.ex#L84)

## TODO

## Test
```ex
  mix test
```

License

See the [LICENSE](https://github.com/zhongwencool/maxwell/blob/master/LICENSE) file for license rights and limitations (MIT).

