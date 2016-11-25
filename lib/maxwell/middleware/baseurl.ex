defmodule Maxwell.Middleware.BaseUrl do
  @moduledoc  """
  ```ex
  #Client.ex
  use Maxwell.Builder ~(get)a
  @middleware Maxwell.Middleware.BaseUrl "http{s}://example.com"

  def request do
    # request http{s}://example.com"
    Client.get!
  end

  def request(path) do
    # http{s}://example.com/path"
    url(path) |> Client.get!
  end

  def request_other() do
    # http{s}://other.com/other_path"
    url("http{s}://other.com/other_path") |> Client.get!
  end
  ```
  Add query to url

  ```ex
  def request(url, query)when is_map(query) do
    url(url) |> query(query) |> Client.get!
  end
  ```
  """
  use Maxwell.Middleware

  def request(env, base_url) do
    if Regex.match?(~r/^https?:\/\//, env.url) do
      env
    else
      %{env | url: base_url <> env.url}
    end
  end

end

