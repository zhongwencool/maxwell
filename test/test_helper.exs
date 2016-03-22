
defmodule Maxwell.TestHelper do
  def call(mid, env, opts) do
    mid.call(env, fn x -> x end, opts)
  end
end

ExUnit.start()
