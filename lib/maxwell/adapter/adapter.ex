defmodule Maxwell.Adapter do
@moduledoc  """
  Example see `Maxwell.Adapter.Ibrowse`
  """

  @type return_t :: {:ok, Maxwell.t} | {:ok, reference} | {:error, any}
  @callback call(Maxwell.t) :: return_t
end
