defmodule Maxwell.Adapter do
  @moduledoc  """
  Define adapter behaviour.

  ### Examples
  See `Maxwell.Adapter.Ibrowse`.
  """
  @type return_t :: Maxwell.Conn.t | {:error, any, Maxwell.Conn.t}

  @callback send_direct(Maxwell.Conn.t) :: return_t
  @callback send_file(Maxwell.Conn.t) :: return_t

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour Maxwell.Adapter

      alias Maxwell.Conn
      alias Maxwell.Adapter.Util

      @doc false
      @spec call(Conn.t) :: Conn.t | {:error, reason :: any(), Conn.t}
      def call(conn) do
        res = case conn.req_body do
          {:multipart, _} -> send_multipart(conn)
          {:file, _}      -> send_file(conn)
          %Stream{}       -> send_stream(conn)
          _               -> send_direct(conn)
        end
        case res do
          %Conn{} -> res
          {:error, _reason, _conn} -> res
          other ->
            raise "invalid return from #{unquote(__CALLER__.module)}" <>
                  " expected Maxwell.Conn.t or {:error, reason}, but got: #{inspect other}"
        end
      end

      @doc """
      Send request without chang it's body formant.

      * `conn` - `%Maxwell.Conn{}`

      Returns `{:ok, %Maxwell.Conn{}}` or `{:error, reason_term, %Maxwell.Conn{}}`.
      """
      def send_direct(conn) do
        raise Maxwell.Error, {__MODULE__, "#{__MODULE__} Adapter doesn't implement send_direct/1", conn}
      end

      @doc """
      Send file request.

      * `conn` - `%Maxwell.Conn{}`, the req_body is `{:file, filepath}`.
      Auto change to chunked mode if req_headers has `%{"transfer-encoding" => "chunked"`

      Returns `{:ok, %Maxwell.Conn{}}` or `{:error, reason_term, %Maxwell.Conn{}}`.
      """
      def send_file(conn) do
        raise Maxwell.Error, {__MODULE__, "#{__MODULE__} Adapter doesn't implement send_file/1", conn}
      end

      @doc """
      Send stream request.

      * `conn` - `%Maxwell.Conn{}`, the req_body is `Stream`.
      Always chunked mode

      Returns `{:ok, %Maxwell.Conn{}}` or `{:error, reason_term, %Maxwell.Conn{}}`.
      """
      def send_stream(conn) do
        raise Maxwell.Error, {__MODULE__, "#{__MODULE__} Adapter doesn't implement send_stream/1", conn}
      end

      defp send_multipart(conn) do
        %Conn{req_body: {:multipart, multiparts}} = conn
        {req_headers, req_body} = Util.multipart_encode(conn, multiparts)
        send_direct(%Conn{conn | req_headers: req_headers, req_body: req_body})
      end

      defoverridable [send_direct: 1, send_file: 1, send_stream: 1] end
  end

end

