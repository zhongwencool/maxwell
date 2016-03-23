# Maxwell

Maxwell is an HTTP client. It borrow idea from [tesla(elixir)](https://github.com/teamon/tesla) which base on [Faraday(ruby)](https://github.com/lostisland/faraday)
It support for middleware and multiple adapters.

## Basic usage

## Get/1 request example
```ex
iex> Maxwell.get(url: "http://httpbin.org/ip")
{:ok,
 %Maxwell{body: '{\n  "origin": "xx.xxx.xxx.xxx"\n}\n',
   headers: %{'Access-Control-Allow-Credentials' => 'true'},
   method: :get, opts: [], status: 200, url: "http://httpbin.org/ip"}}

iex> Maxwell.get!(url: "http://httpbin.org/get", query: %{a: 1, b: "foo"})
%Maxwell{body: '{\n  "args": {\n    "a": "1", \n    "b": "foo"\n  }...',
  headers: %{'Access-Control-Allow-Credentials' => 'true'},
  method: :get, opts: [], status: 200, url: "http://httpbin.org/get?a=1&b=foo"}}
```

## Post!/1 request example 
```ex
iex> Maxwell.post!(url: "http://httpbin.org/post", body: "foo_body")
%Maxwell{body: '{\n  "args": {}, \n  "data": "foo_body_", \n  ...\n',
  headers: %{'Access-Control-Allow-Credentials' => 'true'},
  method: :post, opts: [], status: 200, url: "http://httpbin.org/post"}
```
> **Compare to other http client **: [Compare Example](https://github.com/zhongwencool/maxwell/blob/master/example/github_client.ex)
 
## Request parameters
```ex
[url:        request_url_string,
 headers:    request_headers_map,
 query:      request_query_map,
 body:       request_body_term,
 opts:       request_opts_keyword_list,
 respond_to: pid]
```
`h Maxwell.#{method}` will help you

## Reponse result 
```ex
{:ok,
  %Maxwell{
    headers: reponse_headers_map,
    status:  reponse_http_status_integer,
    body:    reponse_body_term,
    opts:    request_opts_keyword_list,
    url:     request_urlwithquery_string,    
  }}

# or
{:error, reason_term} 
  
```
## Creating API clients

Use `Maxwell.Builder` module to create API wrappers.

For example

```ex
defmodule GitHub do
  # create get/1, get!/1, post/1, post!/1  
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
default adapter is `Maxwell.Adapter.Ibrowse`

NOTE: Remember to include adapter(ibrowse) in applications list.

## Middleware

### Basic

- `Maxwell.Middleware.BaseUrl` - set base url for all request
- `Maxwell.Middleware.Headers` - set request headers
- `Maxwell.Middleware.Opts` - set options for all request
- `Maxwell.Middleware.DecodeRels` - decode reponse rels

### JSON
NOTE: default requires [poison](https://github.com/devinus/poison) as dependency

- `Maxwell.Middleware.EncodeJson` - endode request body as JSON, it will add %{'Content-Type': 'application/json'} to headers
- `Maxwell.Middleware.DecodeJson` - decode response body as JSON

Example 
```ex
middleware Maxwell.Middleware.EncodeJson &Poison.encode/1
middleware Maxwell.Middleware.DecodeJson &Poison.decode/1
```

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

For example, request logger middleware could be implemented like this:

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

Maxwell.get(url: "http://example.org", respond_to: self)

receive do
  {:maxwell_response, res} -> res.status # => 200
end
```

## todo

- [] hackney adapter 
 
