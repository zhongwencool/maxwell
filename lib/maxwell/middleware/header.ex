defmodule Maxwell.Middleware.Headers do
@moduledoc  """
  Add fixed headers to request's headers

  ```ex
  # Client.ex
  use Maxwell.Builder ~(get)a
  @middleware Maxwell.Middleware.Headers %{'User-Agent' => "zhongwencool"}

  def request do
    # headers is merge to %{'User-Agent' => "zhongwencool", 'username' => "zhongwencool"}
    [header: %{'username' => "zhongwencool"}] |> get!
  end
  ```
  """
  use Maxwell.Middleware
  def call(env, run, headers) do
    headers = Map.merge(headers, env.headers)
    %{env | headers: headers}
    |> run.()
  end

end
