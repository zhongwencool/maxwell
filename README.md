# Maxwell

[![Build Status](https://travis-ci.org/zhongwencool/maxwell.svg?branch=master)](https://travis-ci.org/zhongwencool/maxwell)
[![Coveralls Coverage](https://img.shields.io/coveralls/zhongwencool/maxwell.svg)](https://coveralls.io/github/zhongwencool/maxwell)

Maxwell is an HTTP client that provides a common interface over many adapters (such as hackney, ibrowse) and embraces the concept of Rack middleware when processing the request/response cycle.

It borrow idea from [tesla(elixir)](https://github.com/teamon/tesla) which losely base on [Faraday(ruby)](https://github.com/lostisland/faraday)

We already have httpoison and httpotion, why we need another wrapper?

I am trouble with define a lot of `process_url/1` `process_request_headers` `process_response_body` functions,

but those functions almost the same in most cases, we don't need define then every time.

the same operation steps:

1. Put query and url encode together;
2. Add headers
3. Add body
4. Need encode request body with json or multipart
5. Accord reponse's header to decode response body by self
  
So Maxwell make those same steps into middlewares, it don't lose any flexible.

[See the specific example here](https://gist.github.com/zhongwencool/6cd44df1acd699fc9c7159882ef3b597).

## Usage

Use `Maxwell.Builder` module to create API wrappers.

```ex
defmodule GitHub do
  # create get/1, get!/1
  use Maxwell.Builder, ~w(get patch)a

  middleware Maxwell.Middleware.BaseUrl, "https://api.github.com"
  middleware Maxwell.Middleware.Opts, [connect_timeout: 3000]
  middleware Maxwell.Middleware.Headers, %{'Content-Type': "application/vnd.github.v3+json", 'User-Agent': 'zhongwenool'}
  middleware Maxwell.Middleware.EncodeJson
  middleware Maxwell.Middleware.DecodeJson

  adapter Maxwell.Adapter.Ibrowse

  # List public repositories for the specified user.
  # :ibrowse.send_req('https://api.github.com/users/zhongwencool/repos', [\"Content-Type\": \"application/vnd.github.v3+json\", \"User-Agent\": 'zhongwenool'], :get, [], [connect_timeout: 3000])
  def user_repos(username) do
    url("/users/" <> username <> "/repos") |> get!
  end

  # Edit owner repositories
  # :ibrowse.send_req('https://api.github.com/repos/owner/repo', [\"Content-Type\": \"application/vnd.github.v3+json\", \"User-Agent\": 'zhongwenool'], :patch, \"{\\\"name\\\":\\\"name\\\",\\\"description\\\":\\\"desc\\\"}\", [connect_timeout: 3000])"
  def edit_repo_desc(owner, repo, name, desc) do
    url("/repos/#{owner}/#{repo}")
    |> body(%{name: name, description: desc})
    |> patch!
  end
end
```
It auto package all middleware's params(url, query, headers, opts, encode_requet_body, decode_response_body) to adapter(ibrowse)

More example see `h Maxwell`

## Request helper functions
```ex
  url(request_url_string_or_char_list)
  |> query(request_query_map)
  |> headers(request_headers_map)
  |> opts(request_opts_keyword_list)
  |> body(request_body_term)
  |> YourClient.{http_method}! 
```
### Mulipart helper function 
```ex
  multipart(maxwell \\ %Maxwell, request_multipart_list) -> new_maxwell # same as hackney   
```
More info: [Mulipart format](#Mulipart)
### Asynchronous helper function 
```ex
  respond_to(maxwell \\ %Maxwell, target_pid) -> new_maxwell   
```
More info: [Asynchronous Request](#Asynchronous requests)

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

## Installation

  1. Add maxwell to your list of dependencies in `mix.exs`:
```ex
   def deps do
     [{:maxwell, github: "zhongwencool/maxwell", branch: master}]
   end
```
  2. Ensure maxwell is started before your application:
```ex
   def application do
      [applications: [:maxwell]] # also add your adapter(ibrowse,hackney...) here 
   end
```
## Adapters

Maxwell has support for different adapters that do the actual HTTP request processing.

### ibrowse

Maxwell has built-in support for [ibrowse](https://github.com/cmullaparthi/ibrowse) Erlang HTTP client.

To use it simply include `adapter Maxwell.Adapter.Ibrowse` line in your API client definition.
global default adapter

```ex 
config :maxwell,
  default_adapter: Maxwell.Adapter.Ibrowse
```  

NOTE: Remember to include ibrowse(adapter) in applications list.
### hackney

Maxwell has built-in support for [hackney](https://github.com/benoitc/hackney) Erlang HTTP client.

To use it simply include `adapter Maxwell.Adapter.Hackney` line in your API client definition.
global default adapter

```ex 
config :maxwell,
  default_adapter: Maxwell.Adapter.Hackney
```  

NOTE: Remember to include hackney(adapter) in applications list.

## Middleware

### Basic

- `Maxwell.Middleware.BaseUrl` - set base url for all request
- `Maxwell.Middleware.Headers` - set request headers
- `Maxwell.Middleware.Opts` - set options for all request
- `Maxwell.Middleware.DecodeRels` - decode reponse rels

### JSON
NOTE: default requires [poison](https://github.com/devinus/poison) as dependency

- `Maxwell.Middleware.EncodeJson` - endode request body as JSON, it will add 'Content-Type' to headers
- `Maxwell.Middleware.DecodeJson` - decode response body as JSON

Custom json library example 

```ex
@middleware Maxwell.Middleware.EncodeJson, [encode_func: &Poison.encode/1, content_type: "text/javascript"]  
@middleware Maxwell.Middleware.DecodeJson [decode_func: &Poison.decode/1, valid_types: ["text/html"] ]
```
Encode body by encode_func then add %{'Content-Type': content_type} to headers(default content_type is "application/json")

Decode body if 'content-type' in ["text/html","application/json", "text/javascript"]

Default only decode body when it's ["application/json", "text/javascript"]    

## Writing your own middleware

A Maxwell middleware is a module with `call/3` function:

```ex
defmodule MyMiddleware do
  def call(env = %maxwell{}, run, options) do
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
    res = run.(env) # the adapter always return {:ok, env}/{:ok, ref_id}/{error, reason}
    IO.inspect res # print response
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

## Multipart
```ex
response = 
  [url: "http://httpbin.org/post", multipart: [{"name", "value"}, {:file, "test/maxwell/multipart_test_file.sh"}]]
  |> Client.post!
# reponse.body["files"] is %{"file" => "#!/usr/bin/env bash\necho \"test multipart file\"\n"}

```
both ibrowse and hackney adapter support multipart

`{:multipart: lists}`, lists support: 

1. `{:file, path}`
2. `{:file, path, extra_headers}`
3. `{:file, path, disposition, extra_headers}`
4. `{:mp_mixed, name, mixed_boundary}`
5. `{:mp_mixed_eof, mixed_boundary}`
6. `{name, bin_data}`
7. `{name, bin_data, extra_headers}`
8. `{name, bin_data, disposition, extra_headers}`

All format support as hackney. 
More [example](https://github.com/zhongwencool/maxwell/blob/master/test/maxwell/multipart_test.exs)

License

See the [LICENSE](https://github.com/zhongwencool/maxwell/blob/master/LICENSE) file for license rights and limitations (MIT). 
