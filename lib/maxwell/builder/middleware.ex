defmodule Maxwell.Builder.Middleware do
  @moduledoc"""
  Methods for setting up middlewares
  """

  @doc """
   ```
   * `middlewares` - middlewares module, for example: Maxwell.Middleware.Json
   * `opts` - options setting in compile time, default is [], for example: [encode_func: &Poison.encode/1]
   ## Example
    @middleware Middleware.Module, opts\\[]
   ```
  """
  defmacro middleware(middleware, opts\\[]) do
    quote do
      @middleware {unquote(middleware), unquote(middleware).init(unquote(opts))}
    end
  end

end

