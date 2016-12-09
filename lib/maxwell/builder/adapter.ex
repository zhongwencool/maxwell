defmodule Maxwell.Builder.Adapter do
  @moduledoc """
  Adapter macro.

  ### Examples
      # module
      @adapter Adapter.Module

  """

  @doc """
  * `adapter` - adapter module, for example: `Maxwell.Middleware.Hackney`

  ### Examples
       @adapter Adapter.Module
  """
  defmacro adapter(adapter) do
    quote do
      @adapter unquote(adapter)
    end
  end
end
