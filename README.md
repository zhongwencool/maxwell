# Maxwell

Maxwell is an HTTP client. It similar to [Maxwell](https://github.com/teamon/Maxwell) (base on [Faraday](https://github.com/lostisland/faraday))
It embraces the concept of middleware when processing the request/response cycle.

## Basic usage

```ex
# Example get request
iex> Maxwell.get(url: "http://httpbin.org/ip")
{:ok,
 %Maxwell{_module_: Maxwell, body: '{\n  "origin": "xx.xxx.xxx.xxx"\n}\n',
  headers: %{'Access-Control-Allow-Credentials' => 'true'},
  method: :get, opts: [], status: 200, url: "http://httpbin.org/ip"}}

iex> Maxwell.get!(url: "http://httpbin.org/get", query: %{a: 1, b: "foo"})
%Maxwell{_module_: Maxwell,
 body: '{\n  "args": {\n    "a": "1", \n    "b": "foo"\n  }...',
 headers: %{'Access-Control-Allow-Credentials' => 'true'},
 method: :get, opts: [], status: 200, url: "http://httpbin.org/get?a=1&b=foo"}}
```

# Example post request
```ex
iex> Maxwell.post!(url: "http://httpbin.org/post", body: "foo")
%Maxwell{_module_: Maxwell,
 body: '{\n  "args": {}, \n  "data": "foo", \n  ...\n',
 headers: %{'Access-Control-Allow-Credentials' => 'true'},
 method: :post, opts: [], status: 200, url: "http://httpbin.org/post"}
```
## Creating API clients

Use `Maxwell.Builder` module to create API wrappers.

For example

```ex
defmodule GitHub do
  use Maxwell.Builder, ~w(get post)a
  
  middleware Maxwell.Middleware.BaseUrl, "https://api.github.com"
  middleware Maxwell.Middleware.Opts, [connect_timeout: 3000]
  middleware Maxwell.Middleware.Headers, %{'Content-Type': "application/vnd.github.v3+json", 'User-Agent': 'zhongwenool'}
  middleware Maxwell.Middleware.DecodeJson  

  adapter Maxwell.Adapter.Ibrowse

  def user_repos(login) do
    get(url: "/user/" <> login <> "/repos")
  end
end
```

Then use it like this:

```ex
GitHub.get(url: "/user/zhongwencool/repos")
GitHub.user_repos(url: "zhonngwencool")
```

## Installation

  1. Add maxwell to your list of dependencies in `mix.exs`:

        def deps do
          [{:maxwell, github: "zhongwencool/maxwell", branch: master}]
        end

  2. Ensure maxwell is started before your application:

        def application do
          [applications: [:maxwell]]
        end

## Adapters

Maxwell has support for different adapters that do the actual HTTP request processing.

### ibrowse

Maxwell has built-in support for [ibrowse](https://github.com/cmullaparthi/ibrowse) Erlang HTTP client.

To use it simply include `adapter Mawell.Adapter.Ibrowse` line in your API client definition.

NOTE: Remember to include ibrowse in applications list.
## Middleware

### Basic

- `Maxwell.Middleware.BaseUrl` - set base url for all request
- `Maxwell.Middleware.Headers` - set request headers
- `Maxwell.Middleware.Opts` - set options for all request
- `Maxwell.Middleware.body` - set request body
- `Maxwell.Middleware.DecodeRels` - decode reponse rels

### JSON
NOTE: default requires [poison](https://github.com/devinus/poison) as dependency
config by
```ex
config :maxwell, json_lib: Poison
```

- `Maxwell.Middleware.DecodeJson` - decode response body as JSON
- `Maxwell.Middleware.EncodeJson` - endode request body as JSON

## Writing your own middleware

A Maxwell middleware is a module with `call/3` function:

```ex
defmodule MyMiddleware do
  def call(env, run, options) do
    # ...
  end
end
```

The arguments are:
- `env` - `%Maxwell{}` instance
- `run` - continuation function for the rest of middleware/adapter stack
- `options` - arguments passed during middleware configuration (`middleware MyMiddleware, options`)

There is no distinction between request and response middleware, it's all about executing `run` function at the correct time.

For example, z request logger middleware could be implemented like this:

```ex
defmodule Maxwell.Middleware.RequestLogger do
  def call(env, run, _) do
    IO.inspect env # print request env
    run.(env)
  end
end
```

and response logger middleware like this:

```ex
defmodule Maxwell.Middleware.ResponseLogger do
  def call(env, run, _) do
    res = run.(env)
    IO.inspect res # print response env
    res
  end
end
```

## Asynchronous requests

If adapter supports it, you can make asynchronous requests by passing `respond_to: pid` option:

```ex

Maxwell.get("http://example.org", respond_to: self)

receive do
  {:maxwell_response, res} -> res.status # => 200
end
```

## todo