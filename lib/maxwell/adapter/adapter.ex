defmodule Maxwell.Adapter do
  @moduledoc  """
  Define adapter behaviour.

  ### Examples
  See `Maxwell.Adapter.Ibrowse`.
  """

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour Maxwell.Adapter

      alias Maxwell.Conn
      alias Maxwell.Adapter.Util

      @doc false
      def call(conn) do
        case conn.req_body do
          {:multipart, _} -> send_multipart(conn)
          {:file, _} -> send_file(conn)
          %Stream{} -> send_stream(conn)
          _ -> send_direct(conn)
        end
      end

      @doc false
      def send_direct(conn) do
        raise Maxwell.Error, {__MODULE__, "#{__MODULE__} Adapter doesn't implement send_direct/1", conn}
      end
      @doc false
      def send_multipart(conn) do
        raise Maxwell.Error, {__MODULE__, "#{__MODULE__} Adapter doesn't implement send_multipart/1", conn}
      end
      @doc false
      def send_file(conn) do
        raise Maxwell.Error, {__MODULE__, "#{__MODULE__} Adapter doesn't implement send_file/1", conn}
      end
      @doc false
      def send_stream(conn) do
        raise Maxwell.Error, {__MODULE__, "#{__MODULE__} Adapter doesn't implement send_stream/1", conn}
      end

      defoverridable [send_direct: 1, send_multipart: 1, send_file: 1, send_stream: 1] end
  end

  @type return_t :: {:ok, Maxwell.Conn.t} | {:error, any, Maxwell.Conn.t}
  @callback send_direct(Maxwell.Conn.t) :: return_t
  @callback send_multipart(Maxwell.Conn.t) :: return_t
  @callback send_file(Maxwell.Conn.t) :: return_t

end

