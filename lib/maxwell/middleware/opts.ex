defmodule Maxwell.Middleware.Opts do
  @moduledoc  """
  Merge adapter's options (keyword list) to adapter's options

  ## Examples
  ```ex
  # Client.ex
  use Maxwell.Builder ~(get)a
  @middleware Maxwell.Middleware.Opts [connect_timeout: 5000]

  def request do
    # opts is [connect_timeout: 5000, cookie: "xxxxcookieyyyy"]
    put_option(cookie: "xxxxcookieyyyy")|> get!
  end
  ```
  """
  use Maxwell.Middleware

  def request(env, opts) do
    new_opts = Keyword.merge(opts, env.opts)
    %{env | opts: new_opts}
  end

end

