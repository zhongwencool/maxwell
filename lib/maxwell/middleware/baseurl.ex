defmodule Maxwell.Middleware.BaseUrl do
  def call(env, run, base_url) do
   unless Regex.match?(~r/^https?:\/\//, env.url) do
     %{env | url: base_url <> env.url}
   else
     env
   end
   |> run.()
  end

end
