defmodule Maxwell.Middleware.Opts do
  def call(env, run, opts) do
    new_opts = Keyword.merge(opts, env.opts)
    %{env | opts: new_opts}
    |> run.()
  end

end
