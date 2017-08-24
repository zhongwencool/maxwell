defmodule Maxwell.Error do
  @moduledoc  """
  Exception `%Maxwell.Error{:url, :reason, :message, :status, :conn}`
  ### Examples

      raise Maxwell.Error, {__MODULE__, reason, conn}

  """
  defexception [:url, :status, :method, :reason, :message, :conn]

  @spec exception({module, atom | binary, Maxwell.Conn.t}) :: Exception.t
  def exception({module, reason, conn}) do
    %Maxwell.Conn{url: url, status: status, method: method, path: path} = conn
    message = """
    url: #{url}
    path: #{inspect path}
    method: #{method}
    status: #{status}
    reason: #{inspect reason}
    module: #{module}
    """
    %Maxwell.Error{url: url, status: status, method: method, message: message, conn: conn}
  end

end
