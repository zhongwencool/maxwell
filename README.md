# Maxwell

[![Build Status](https://travis-ci.org/zhongwencool/maxwell.svg?branch=master)](https://travis-ci.org/zhongwencool/maxwell)
[![Inline docs](http://inch-ci.org/github/zhongwencool/maxwell.svg)](http://inch-ci.org/github/zhongwencool/maxwell)
[![Coveralls Coverage](https://img.shields.io/coveralls/zhongwencool/maxwell.svg)](https://coveralls.io/github/zhongwencool/maxwell)

Maxwell is an HTTP client that provides a common interface over many adapters.

[Documentation for Plug is available online](https://hexdocs.pm/maxwell).

[See the specific example here](https://gist.github.com/zhongwencool/6cd44df1acd699fc9c7159882ef3b597).

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

  adapter Maxwell.Adapter.Hackney # default adapter is Ibrowse

  #List public repositories for the specified user.
  #:hackney.request(:get,
  #                'https://api.github.com/users/zhongwencool/repos',
  #                ['Content-Type': "application/vnd.github.v3+json", 'User-Agent': 'zhongwenool'],
  #                [],
  #                [connect_timeout: 3000])
  def user_repos(username) do
    url("/users/" <> username <> "/repos") |> get
  end

  # Edit owner repositories
  # :hackney.request(:patch,
  #                  'https://api.github.com/repos/owner/repo',
  #                  ['Content-Type': "application/vnd.github.v3+json", 'User-Agent': 'zhongwenool'],
  #                  "{\"name\":\"name\",\"description\":\"desc\"}",
  #                  [connect_timeout: 3000])
  def edit_repo_desc(owner, repo, name, desc) do
    url("/repos/#{owner}/#{repo}")
    |> body(%{name: name, description: desc})
    |> patch
  end
end
```
```ex
MIX_ENV=TEST iex -S mix
iex(1)> GitHubClient.
body/1              body/2              edit_repo_desc/4
get!/0              get!/1              get/0
get/1               headers/1           headers/2
multipart/1         multipart/2         opts/1
opts/2              patch!/0            patch!/1
patch/0             patch/1             query/1
query/2             respond_to/1        respond_to/2
url/1               url/2               user_repos/1
iex(1)> GitHubClient.user_repos("zhongwencool")
23:34:56.632 [info]  GET https://api.github.com/users/zhongwencool/repos
<200(723.052ms)
<
Access-Control-Allow-Origin:*
Access-Control-Expose-Headers:ETag, Link, X-GitHub-OTP, X-RateLimit-Limit...
Cache-Control:public, max-age=60, s-maxage=60
Content-Length:137695
...HEADERS...
<[{"id":48745642,"name":"apns4erl","full_name":"zhongwencool/apns4erl","owner":
...BODY...
...
```
if you don't want to defined a client module:
```ex
iex(2)> Maxwell.url("http://httpbin.org/drip") |> Maxwell.query(%{numbytes: 25, duration: 1, delay: 1, code: 200}) |> Maxwell.get
{:ok,
 %Maxwell{body: '*************************',
  headers: %{'Access-Control-Allow-Credentials' => 'true',
    'Access-Control-Allow-Origin' => '*', 'Connection' => 'keep-alive',
    'Content-Length' => '25', 'Content-Type' => 'application/octet-stream',
    'Date' => 'Thu, 24 Nov 2016 16:04:21 GMT', 'Server' => 'nginx'},
  method: :get, opts: [], status: 200,
  url: "http://httpbin.org/drip?code=200&delay=1&duration=1&numbytes=25"}}
```
### Request helper functions
```ex
  url(request_url_string_or_char_list)
  |> query(request_query_map)
  |> headers(request_headers_map)
  |> opts(request_opts_keyword_list)
  |> body(request_body_term)
  |> YourClient.{http_method}!
```
For more examples see `h Maxwell`

### Multipart helper function
```ex
  multipart(maxwell \\ %Maxwell, request_multipart_list) -> new_maxwell # same as hackney   
```
More info: [Multipart format](#Multipart)
### Asynchronous helper function
```ex
  respond_to(maxwell \\ %Maxwell, target_pid) -> new_maxwell   
```
More info: [Asynchronous Request](#Asynchronous requests)

## Response result
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
     [{:maxwell, "~> 1.1.0"}]
   end
```
  2. Ensure maxwell has started before your application:
```ex
   def application do
      [applications: [:maxwell]] # **also add your adapter(ibrowse,hackney...) here **
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

NOTE: Remember to include `:ibrowse` in applications list.
### hackney

Maxwell has built-in support for [hackney](https://github.com/benoitc/hackney) Erlang HTTP client.

To use it simply include `adapter Maxwell.Adapter.Hackney` line in your API client definition.
global default adapter

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

## Asynchronous requests

If the adapter supports it, you can make asynchronous requests by passing `respond_to: pid` option:

```ex

Maxwell.get(url: "http://example.org", respond_to: self)

receive do
  {:maxwell_response, {:ok, res}} -> res.status # => 200
  {:maxwell_response, {:error, reason, env}} -> env # the request env
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

All formats supported by hackney.
See more [examples](https://github.com/zhongwencool/maxwell/blob/master/test/maxwell/multipart_test.exs).

## TODO

* Support stream
* more clear document

## Test
```ex
  mix test
```

License

See the [LICENSE](https://github.com/zhongwencool/maxwell/blob/master/LICENSE) file for license rights and limitations (MIT).

