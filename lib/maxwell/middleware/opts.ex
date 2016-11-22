defmodule Maxwell.Middleware.Opts do
@moduledoc  """
  Passthrough adapter's options (keyword list) to adapter's options

  ```ex
  # Client.ex
  use Maxwell.Builder ~(get)a
  @middleware Maxwell.Middleware.Opts [connect_timeout: 5000]

  def request do
    # opts is [connect_timeout: 5000, cookie: "xxxxcookieyyyy"]
    [opts: [cookie: "xxxxcookieyyyy"]]|> get!
  end
  ```
  """
  use Maxwell.Middleware
  def call(env, run, opts) do
    new_opts = Keyword.merge(opts, env.opts)
    %{env | opts: new_opts}
    |> run.()
  end

end
