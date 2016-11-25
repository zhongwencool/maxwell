defmodule Maxwell do
  @moduledoc  """
       defmodule Client do
         use Maxwell.Builder, ~w(get post put)a
         adapter Maxwell.Adapter.Ibrowse

         middleware Maxwell.Middleware.BaseUrl,   "http://example.com"
         middleware Maxwell.Middleware.Opts,      [connect_timeout: 1000]
         middleware Maxwell.Middleware.Headers,   %{'User-Agent' => "zhongwencool"}
         middleware Maxwell.Middleware.Json

         # get home page
         # curl --header "User-Agent: zhongwencool" http://example.com
         def home, do: get!

         # get help info with path
         # curl --header "User-Agent: zhongwencool" http://example.com/help
         def get_help do
           url("/help) |> get!
         end

         # get user info with query
         # curl --header "User-Agent: zhongwencool" http://example.com/user?name=username
         def get_user_info(username) do
           url("/user") |> query(%{name: username}) |> get!
         end

         # post user login with json
         # curl -H "Content-Type: application/json" -X POST -d '{"username":"xyz","password":"xyz"}' http://example.com/login
         def login(username, password) do
           url("/login") |> body(%{username: username, password: password}) |> post!
         end

         # upload put multipart form
         # curl --form "file=@filepath" https://example.com/upload
         def upload(filepath, username) do
           url("/upload") |> query(%{username: username}) |> multipart([{:file, filepath}]) |> put!
         end

         # cover adapter(ibrowse) connect_timeout from 1000 to 6000
         def delete(username) do
           url("/delete") |> query(%{username: username}) |> opts([connect_timeout: 6000]) |> delete!
         end
       end
  """
  use Maxwell.Builder

end

