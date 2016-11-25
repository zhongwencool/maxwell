defmodule Maxwell.Builder.Adapter do
  @moduledoc """
  ```
  # module
  @adapter Adapter.Module
  # or function
  @adapter fn(env = %Maxwell.Conn{}) -> {:ok, env = %Maxwell.Conn{}} / {:error, term()} end
  # or local function
  @adapter FunName
  ```
  """
  defmacro adapter({:fn, _, _} = ad) do
    escaped = Macro.escape(ad)
    quote do
      @adapter unquote(escaped)
    end
  end
  defmacro adapter(adapter) do
    quote do
      @adapter unquote(adapter)
    end
  end
end
