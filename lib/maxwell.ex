defmodule Maxwell do
  @moduledoc  """
  #{File.read!("README.md")}
  """
  use Tesla.Builder

  defstruct url: "",
            method: nil,
            headers: %{},
            body: nil,
            opts: [],
            status: nil,
            _module_: nil

end
