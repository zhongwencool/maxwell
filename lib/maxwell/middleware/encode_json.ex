defmodule Maxwell.Middleware.EncodeJson do
  def call(env, run, opts \\ []) do

    if env.body do
      encode = opts[:encode] || &Poison.encode/1
      {:ok, body} = encode.(env.body)
      env = %{env | body: body}
      headers = %{'Content-Type': 'application/json'}

      Maxwell.Middleware.Headers.call(env, run, headers)
    else
      run.(env)
    end
  end

end
