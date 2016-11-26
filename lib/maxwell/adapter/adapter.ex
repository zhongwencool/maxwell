defmodule Maxwell.Adapter do
@moduledoc  """
  Example see `Maxwell.Adapter.Ibrowse`
  """
  @type return_t :: {:ok, Maxwell.Conn.t} | {:ok, reference} | {:error, any}
  @callback call(Maxwell.Conn.t) :: return_t
end

