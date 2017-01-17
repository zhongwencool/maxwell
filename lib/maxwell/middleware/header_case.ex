defmodule Maxwell.Middleware.HeaderCase do
  @moduledoc """
  Forces all request headers to be of a certain case.

  ## Examples

      # Lower
      iex> conn = %Maxwell.Conn{req_headers: %{"content-type" => "application/json}}
      ...> Maxwell.Middleware.HeaderCase.request(conn, :lower)
      %Maxwell.Conn{req_headers: %{"content-type" => "application/json}}

      # Upper
      iex> conn = %Maxwell.Conn{req_headers: %{"content-type" => "application/json}}
      ...> Maxwell.Middleware.HeaderCase.request(conn, :upper)
      %Maxwell.Conn{req_headers: %{"CONTENT-TYPE" => "application/json}}

      # Title
      iex> conn = %Maxwell.Conn{req_headers: %{"content-type" => "application/json}}
      ...> Maxwell.Middleware.HeaderCase.request(conn, :title)
      %Maxwell.Conn{req_headers: %{"Content-Type" => "application/json}}
  """
  alias Maxwell.Conn
  def init(casing) when casing in [:lower, :upper, :title] do
    casing
  end
  def init(casing) do
    raise ArgumentError, "HeaderCase middleware expects a casing style of :lower, :upper, or :title - got: #{casing}"
  end

  def request(%Conn{req_headers: headers} = conn, :lower) do
    new_headers = headers
    |> Enum.map(fn {k, v} -> {String.downcase(k), v} end)
    |> Enum.into(%{})
    %{conn | req_headers: new_headers}
  end
  def request(%Conn{req_headers: headers} = conn, :upper) do
    new_headers = headers
    |> Enum.map(fn {k, v} -> {String.upcase(k), v} end)
    |> Enum.into(%{})
    %{conn | req_headers: new_headers}
  end
  def request(%Conn{req_headers: headers} = conn, :title) do
    new_headers = headers
    |> Enum.map(fn {k, v} ->
      tk = k
      |> String.downcase
      |> String.split(~r/[-_]/, include_captures: true, trim: true)
      |> Enum.map(&String.capitalize/1)
      |> Enum.join
      {tk, v}
    end)
    |> Enum.into(%{})
    %{conn | req_headers: new_headers}
  end
end
