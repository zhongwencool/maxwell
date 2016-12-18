defmodule Maxwell.Adapter.TestHelper do
  defmacro __using__([adapter: adapter]) do
    client = adapter |> Macro.expand(__CALLER__) |> Module.concat(TestClient)
    quote location: :keep do
      use ExUnit.Case, async: false
      import Maxwell.Conn

      defmodule unquote(client) do
        use Maxwell.Builder
        adapter unquote(adapter)

        middleware Maxwell.Middleware.BaseUrl, "http://httpbin.org"
        middleware Maxwell.Middleware.Opts, [connect_timeout: 5000]
        middleware Maxwell.Middleware.Json

        def get_ip_test() do
          "/ip" |> put_path |> get!
        end

        def encode_decode_json_test(body) do
          "/post"
          |> put_path
          |> put_req_body(body)
          |> post!
          |> get_resp_body("json")
        end

        def user_agent_test(user_agent) do
          "/user-agent"
          |> put_path
          |> put_req_header("user-agent", user_agent)
          |> get!
          |> get_resp_body("user-agent")
        end

        def put_json_test(json) do
          "/put"
          |> put_path
          |> put_req_body(json)
          |> put!
          |> get_resp_body("data")
        end

        def delete_test() do
          "/delete"
          |> put_path
          |> delete!
          |> get_resp_body("data")
        end

        def multipart_test() do
          "/post"
          |> put_path
          |> put_req_body({:multipart, [{:file, "test/maxwell/multipart_test_file.sh"}]})
          |> post!
        end
        def multipart_with_extra_header_test() do
          "/post"
          |> put_path
          |> put_req_body({:multipart, [{:file, "test/maxwell/multipart_test_file.sh", [{"Content-Type", "image/jpeg"}]}]})
          |> post!
        end

        def file_test(filepath) do
          "/post"
          |> put_path
          |> put_req_body({:file, filepath})
          |> post!
        end

        def file_test(filepath, content_type) do
          "/post"
          |> put_path
          |> put_req_body({:file, filepath})
          |> put_req_header("content-type", content_type)
          |> post!
        end

        def stream_test() do
          "/post"
          |> put_path
          |> put_req_header("content-type", "application/vnd.lotus-1-2-3")
          |> put_req_header("content-length", 6)
          |> put_req_body(Stream.map(["1", "2", "3"], fn(x) -> List.duplicate(x, 2) end))
          |> post!
        end
      end

      setup do
        :random.seed(:erlang.phash2([node()]), :erlang.monotonic_time, :erlang.unique_integer)
        :ok
      end

      test "sync request" do
        assert unquote(client).get_ip_test |> get_status == 200
      end

      test "encode decode json test" do
        result = %{"josnkey1" => "jsonvalue1", "josnkey2" => "jsonvalue2"} |> unquote(client).encode_decode_json_test
        assert result == %{"josnkey1" => "jsonvalue1", "josnkey2" => "jsonvalue2"}

      end

      test "mutilpart body file" do
        conn = unquote(client).multipart_test
        assert get_resp_body(conn, "files") == %{"file" => "#!/usr/bin/env bash\necho \"test multipart file\"\n"}
      end

      test "mutilpart body file extra headers" do
        conn = unquote(client).multipart_with_extra_header_test
        assert get_resp_body(conn, "files") == %{"file" => "#!/usr/bin/env bash\necho \"test multipart file\"\n"}
      end

      test "send file without content-type" do
        conn = unquote(client).file_test("test/maxwell/multipart_test_file.sh")
        assert get_resp_body(conn, "data") == "#!/usr/bin/env bash\necho \"test multipart file\"\n"
      end

      test "send file with content-type" do
        conn = unquote(client).file_test("test/maxwell/multipart_test_file.sh", "application/x-sh")
        assert get_resp_body(conn, "data") == "#!/usr/bin/env bash\necho \"test multipart file\"\n"
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
        assert unquote(client).delete_test == ""
      end

      test "Head without body(test return {:ok, status, header})" do
        body = unquote(client).head! |> get_resp_body |> Kernel.to_string
        assert body == ""
      end
    end

  end

end

