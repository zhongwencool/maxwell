defmodule Maxwell.Middleware.TestHelper do
  def request(mid, env, opts) do
    mid.request(env, opts)
  end
  def response(mid, env, opts) do
    mid.response(env, opts)
  end
end

