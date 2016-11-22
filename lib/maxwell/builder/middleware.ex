defmodule Maxwell.Builder.Middleware do
  @moduledoc"""
  Methods for setting up middlewares
  """

  @doc """
   ```
    @middleware Middleware.Module, opts\\[]
   ```
  """
  defmacro middleware(middleware, opts\\[]) do
    quote do
      @middleware {unquote(middleware), unquote(opts)}
    end
  end

end
