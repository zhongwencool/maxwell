defmodule Maxwell.Middleware.Headers do
  def call(env, run, headers) do
    headers = Map.merge(headers, env.headers)
    %{env | headers: headers}
    |> run.()
  end

end
