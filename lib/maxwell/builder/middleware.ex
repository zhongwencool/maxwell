defmodule Maxwell.Builder.Middleware do
  @moduledoc"""
  Methods for setting up middlewares.
  """

  @doc """
   Build middleware macro.

   * `middleware` - middleware module, for example: `Maxwell.Middleware.Json`.
   * `opts` - options setting in compile time, default is `[]`, for example: `[encode_func: &Poison.encode/1]`.

  ### Examples
        @middleware Middleware.Module, []

  """
  defmacro middleware(middleware, opts \\ []) do
    quote do
      @middleware {unquote(middleware), unquote(middleware).init(unquote(opts))}
    end
  end

end

