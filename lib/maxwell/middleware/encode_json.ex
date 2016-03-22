defmodule Maxwell.Middleware.EncodeJson do
  def call(env, run, encode_fun) do
    unless is_function(encode_fun), do: encode_fun = &Poison.encode/1
    if env.body do
      {:ok, body} = encode_fun.(env.body)
      env = %{env | body: body}
      headers = %{'Content-Type': 'application/json'}

      Maxwell.Middleware.Headers.call(env, run, headers)
    else
      run.(env)
    end
  end

end
