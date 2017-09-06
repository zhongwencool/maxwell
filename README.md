# Maxwell

[![Build Status](https://travis-ci.org/zhongwencool/maxwell.svg?branch=master)](https://travis-ci.org/zhongwencool/maxwell)
[![Inline docs](http://inch-ci.org/github/zhongwencool/maxwell.svg)](http://inch-ci.org/github/zhongwencool/maxwell)
[![Coveralls Coverage](https://img.shields.io/coveralls/zhongwencool/maxwell.svg)](https://coveralls.io/github/zhongwencool/maxwell)
[![Hex.pm](https://img.shields.io/hexpm/v/maxwell.svg)](http://hex.pm/packages/maxwell)

Maxwell is an HTTP client that provides a common interface over [:httpc](http://erlang.org/doc/man/httpc.html), [:ibrowse](https://github.com/cmullaparthi/ibrowse), [:hackney](https://github.com/benoitc/hackney).

[Documentation for Maxwell is available online](https://hexdocs.pm/maxwell).

## Getting Started

The simplest way to use Maxwell is by creating a module which will be your API wrapper, using `Maxwell.Builder`:

```elixir
defmodule GitHubClient do
  # Generates `get/1`, `get!/1`, `patch/1`, `patch!/1` public functions
  # You can omit the list and functions for all HTTP methods will be generated
  use Maxwell.Builder, ~w(get patch)a

  # For a complete list of middlewares, see the docs
  middleware Maxwell.Middleware.BaseUrl, "https://api.github.com"
  middleware Maxwell.Middleware.Headers, %{"content-type" => "application/vnd.github.v3+json", "user-agent" => "zhongwenool"}
  middleware Maxwell.Middleware.Opts,    connect_timeout: 3000
  middleware Maxwell.Middleware.Json
  middleware Maxwell.Middleware.Logger

  # adapter can be omitted, and the default will be used (currently :ibrowse)
  adapter Maxwell.Adapter.Hackney

  # List public repositories for the specified user.
  def user_repos(username) do
    "/users/#{username}/repos"
    |> new()
    |> get()
  end

  # Edit owner repositories
  def edit_repo_desc(owner, repo, name, desc) do
    "/repos/#{owner}/#{repo}"
    |> new()
    |> put_req_body(%{name: name, description: desc})
    |> patch()
  end
end
```

`Maxwell.Builder` injects functions for all supported HTTP methods, in two flavors, the first (e.g. `get/1`) will
return `{:ok, Maxwell.Conn.t}` or `{:error, term, Maxwell.Conn.t}`. The second (e.g. `get!/1`) will return
`Maxwell.Conn.t` *only* if the request succeeds and returns a 2xx status code, otherwise it will raise `Maxwell.Error`.

The same functions are also exported by the `Maxwell` module, which you can use if you do not wish to define a wrapper
module for your API, as shown below:

```elixir
iex(1)> alias Maxwell.Conn
iex(2)> Conn.new("http://httpbin.org/drip") |>
    Conn.put_query_string(%{numbytes: 25, duration: 1, delay: 1, code: 200}) |> 
    Maxwell.get
{:ok,
 %Maxwell.Conn{method: :get, opts: [], path: "/drip",
  query_string: %{code: 200, delay: 1, duration: 1, numbytes: 25},
  req_body: nil, req_headers: %{}, resp_body: '*************************',
  resp_headers: %{"access-control-allow-credentials" => "true",
    "access-control-allow-origin" => "*",
    "connection" => "keep-alive",
    "content-length" => "25",
    "content-type" => "application/octet-stream",
    "date" => "Sun, 18 Dec 2016 14:32:38 GMT",
    "server" => "nginx"}, state: :sent, status: 200,
  url: "http://httpbin.org"}}
```

There are numerous helper functions for the `Maxwell.Conn` struct. See it's module docs
for a list of all functions, and detailed info about how they behave.

## Installation

  1. Add maxwell to your list of dependencies in `mix.exs`:
```ex
   def deps do
     [{:maxwell, "~> 2.2.2"}]
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

To use it simply place `adapter Maxwell.Adapter.Httpc` in your API client definition.

### ibrowse

Maxwell has built-in support for the [ibrowse](https://github.com/cmullaparthi/ibrowse) Erlang HTTP client.

To use it simply place `adapter Maxwell.Adapter.Ibrowse` in your API client definition.

**NOTE**: Remember to include `:ibrowse` in your applications list.

### hackney

Maxwell has built-in support for the [hackney](https://github.com/benoitc/hackney) Erlang HTTP client.

To use it simply place `adapter Maxwell.Adapter.Hackney` in your API client definition.

**NOTE**: Remember to include `:hackney` in your applications list.

## Built-in Middleware

### Maxwell.Middleware.BaseUrl

Sets the base url for all requests.

### Maxwell.Middleware.Headers

Sets default headers for all requests.

### Maxwell.Middleware.HeaderCase

Enforces that all header keys share a specific casing style, e.g. lower-case,
upper-case, or title-case.

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

