defmodule Maxwell.Adapter.TestHelper do
  defmacro __using__(adapter: adapter) do
    client = adapter |> Macro.expand(__CALLER__) |> Module.concat(TestClient)

    quote location: :keep do
      use ExUnit.Case, async: false
      import Maxwell.Conn

      defmodule unquote(client) do
        use Maxwell.Builder
        adapter unquote(adapter)

        middleware Maxwell.Middleware.BaseUrl, "http://httpbin.org"
        middleware Maxwell.Middleware.Opts, connect_timeout: 5000
        middleware Maxwell.Middleware.Json

        def get_ip_test() do
          "/ip" |> new() |> get!()
        end

        def encode_decode_json_test(body) do
          "/post"
          |> new()
          |> put_req_body(body)
          |> post!
          |> get_resp_body("json")
        end

        def user_agent_test(user_agent) do
          "/user-agent"
          |> new()
          |> put_req_header("user-agent", user_agent)
          |> get!
          |> get_resp_body("user-agent")
        end

        def put_json_test(json) do
          "/put"
          |> new()
          |> put_req_body(json)
          |> put!
          |> get_resp_body("data")
        end

        def delete_json_test(json) do
          "delete"
          |> new()
          |> put_req_body(json)
          |> delete!
          |> get_resp_body("data")
        end

        def multipart_test() do
          "/post"
          |> new()
          |> put_req_body({:multipart, [{:file, "test/maxwell/multipart_test_file.sh"}]})
          |> post!
        end

        def multipart_file_content_test() do
          "/post"
          |> new()
          |> put_req_body({:multipart, [{:file_content, "xxx", "test.txt"}]})
          |> post!
        end

        def multipart_with_extra_header_test() do
          "/post"
          |> new()
          |> put_req_body(
            {:multipart,
             [{:file, "test/maxwell/multipart_test_file.sh", [{"Content-Type", "image/jpeg"}]}]}
          )
          |> post!
        end

        def file_test(filepath, content_type) do
          "/post"
          |> new()
          |> put_req_body({:file, filepath})
          |> put_req_header("content-type", content_type)
          |> post!
        end

        def file_test(filepath) do
          "/post"
          |> new()
          |> put_req_header("content-type", "application/vnd.lotus-1-2-3")
          |> put_req_body({:file, filepath})
          |> post!
        end

        def stream_test() do
          "/post"
          |> new()
          |> put_req_header("content-type", "application/vnd.lotus-1-2-3")
          |> put_req_header("content-length", 6)
          |> put_req_body(Stream.map(["1", "2", "3"], fn x -> List.duplicate(x, 2) end))
          |> post!
        end

        def file_without_transfer_encoding_test(filepath, content_type) do
          "/post"
          |> new()
          |> put_req_body({:file, filepath})
          |> put_req_header("content-type", content_type)
          |> post!
        end
      end

      if Code.ensure_loaded?(:rand) do
        setup do
          :rand.seed(
            :exs1024,
            {:erlang.phash2([node()]), :erlang.monotonic_time(), :erlang.unique_integer()}
          )

          :ok
        end
      else
        setup do
          :random.seed(
            :erlang.phash2([node()]),
            :erlang.monotonic_time(),
            :erlang.unique_integer()
          )

          :ok
        end
      end

      test "sync request" do
        assert unquote(client).get_ip_test |> get_status == 200
      end

      test "encode decode json test" do
        result =
          %{"josnkey1" => "jsonvalue1", "josnkey2" => "jsonvalue2"}
          |> unquote(client).encode_decode_json_test

        assert result == %{"josnkey1" => "jsonvalue1", "josnkey2" => "jsonvalue2"}
      end

      test "multipart body file" do
        conn = unquote(client).multipart_test

        assert get_resp_body(conn, "files") == %{
                 "file" => "#!/usr/bin/env bash\necho \"test multipart file\"\n"
               }
      end

      test "multipart body file_content" do
        conn = unquote(client).multipart_file_content_test
        assert get_resp_body(conn, "files") == %{"file" => "xxx"}
      end

      test "multipart body file extra headers" do
        conn = unquote(client).multipart_with_extra_header_test

        assert get_resp_body(conn, "files") == %{
                 "file" => "#!/usr/bin/env bash\necho \"test multipart file\"\n"
               }
      end

      test "send file without content-type" do
        conn = unquote(client).file_test("test/maxwell/multipart_test_file.sh")

        assert get_resp_body(conn, "data") ==
                 "#!/usr/bin/env bash\necho \"test multipart file\"\n"
      end

      test "send file with content-type" do
        conn =
          unquote(client).file_test("test/maxwell/multipart_test_file.sh", "application/x-sh")

        assert get_resp_body(conn, "data") ==
                 "#!/usr/bin/env bash\necho \"test multipart file\"\n"
      end

      test "file_without_transfer_encoding" do
        conn =
          unquote(client).file_without_transfer_encoding_test(
            "test/maxwell/multipart_test_file.sh",
            "application/x-sh"
          )

        assert get_resp_body(conn, "data") ==
                 "#!/usr/bin/env bash\necho \"test multipart file\"\n"
      end

      test "send stream" do
        conn = unquote(client).stream_test
        assert get_resp_body(conn, "data") == "112233"
      end

      test "user-agent header test" do
        assert "test" |> unquote(client).user_agent_test == "test"
      end

      test "/put" do
        assert %{"key" => "value"} |> unquote(client).put_json_test == "{\"key\":\"value\"}"
      end

      test "/delete" do
        assert %{"key" => "value"} |> unquote(client).delete_json_test == "{\"key\":\"value\"}"
      end

      test "Head without body(test return {:ok, status, header})" do
        body = unquote(client).head! |> get_resp_body |> Kernel.to_string()
        assert body == ""
      end
    end
  end
end
