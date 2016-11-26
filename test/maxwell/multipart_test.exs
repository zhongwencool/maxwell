defmodule MultipartTest do
  use ExUnit.Case

  setup do
    :random.seed(:erlang.phash2([node()]), :erlang.monotonic_time, :erlang.unique_integer)
    :ok
  end

  test "Boundary" do
    boundary = Maxwell.Multipart.new_boundary
    assert byte_size(boundary) == 43
    assert String.valid?(boundary) == true
  end

  test "File base" do
    boundary = Maxwell.Multipart.new_boundary
    file_path = "test/maxwell/multipart_test_file.sh"
    {body, size} = Maxwell.Multipart.encode(boundary, [{:file, file_path}])
    #hackney = :hackney_multipart.encode_form([{:file, file_path}], boundary)
    assert size == 279
    assert String.starts_with?(body, "--" <> boundary) == true
    assert String.ends_with?(body, boundary <> "--\r\n") == true
    assert String.replace(body, boundary, "") == "--\r\ncontent-length: 47\r\ncontent-disposition: form-data; name=\"file\"; filename=\"multipart_test_file.sh\"\r\ncontent-type: application/x-sh\r\n\r\n#!/usr/bin/env bash\necho \"test multipart file\"\n\r\n----\r\n"
  end

  test "File ExtraHeaders" do
    boundary = Maxwell.Multipart.new_boundary
    file_path = "test/maxwell/multipart_test_file.sh"
    extra_headers = [{"Content-Type", "image/jpeg"}]
    {body, size} = Maxwell.Multipart.encode(boundary, [{:file, file_path, extra_headers}])
    # hackney = :hackney_multipart.encode_form([{:file, file_path, extra_headers}], boundary)
    assert size == 273
    assert String.starts_with?(body, "--" <> boundary) == true
    assert String.ends_with?(body, boundary <> "--\r\n") == true
    assert String.replace(body, boundary, "") == "--\r\ncontent-length: 47\r\ncontent-disposition: form-data; name=\"file\"; filename=\"multipart_test_file.sh\"\r\ncontent-type: image/jpeg\r\n\r\n#!/usr/bin/env bash\necho \"test multipart file\"\n\r\n----\r\n"
  end

  test "File Disposition" do
    boundary = Maxwell.Multipart.new_boundary
    file_path = "test/maxwell/multipart_test_file.sh"
    extra_headers = [{"Content-Type", "image/jpeg"}]
    disposition = {'form-data', [{"name", "content"}, {"filename", file_path}]}
    {body, size} = Maxwell.Multipart.encode(boundary, [{:file, file_path, disposition, extra_headers}])
    # hackney = :hackney_multipart.encode_form([{:file, file_path, disposition, extra_headers}], boundary)
    assert size == 285
    assert String.starts_with?(body, "--" <> boundary) == true
    assert String.ends_with?(body, boundary <> "--\r\n") == true
    assert String.replace(body, boundary, "") == "--\r\ncontent-length: 47\r\ncontent-disposition: form-data; name=content; filename=test/maxwell/multipart_test_file.sh\r\ncontent-type: image/jpeg\r\n\r\n#!/usr/bin/env bash\necho \"test multipart file\"\n\r\n----\r\n"
  end

  test "mp_mixed name mixedboudnary" do
    boundary = Maxwell.Multipart.new_boundary
    name = "mp_mixed_test_name"
    mixed_boundary = Maxwell.Multipart.new_boundary
    # hackney = :hackney_multipart.encode_form([{:mp_mixed, name, mixed_boundary}], boundary)
    {body, size} = Maxwell.Multipart.encode(boundary, [{:mp_mixed, name, mixed_boundary}])
    body1 = "--#{mixed_boundary}\r\nContent-Disposition: form-data; name=\"mp_mixed_test_name\"\r\nContent-Type: multipart/mixed; boundary=#{mixed_boundary}\r\n\r\n\r\n--#{boundary}--\r\n"
    assert size == 244
    assert body1 == body

  end

  test "mp_mixed_eof mixedboudnary" do
    boundary = Maxwell.Multipart.new_boundary
    mixed_boundary = Maxwell.Multipart.new_boundary
    # hackney = :hackney_multipart.encode_form([{:mp_mixed_eof, mixed_boundary}], boundary)
    {body, size} = Maxwell.Multipart.encode(boundary, [{:mp_mixed_eof, mixed_boundary}])
    body1 = "--#{mixed_boundary}--\r\n\r\n--#{boundary}--\r\n"
    assert size == 100
    assert body1 == body

  end

  test "name binary" do
    boundary = Maxwell.Multipart.new_boundary
    name = "test_name"
    bin = "test_binary"
    # hackney = :hackney_multipart.encode_form([{name, bin}], boundary)
    {body, size} = Maxwell.Multipart.encode(boundary, [{name, bin}])
    body1 = "--#{boundary}\r\ncontent-length: 11\r\ncontent-type: application/octet-stream\r\ncontent-disposition: form-data; name=\"test_name\"\r\n\r\ntest_binary\r\n--#{boundary}--\r\n"
    assert size == 221
    assert body1 == body

  end

  test "name binary extraheaders" do
    boundary = Maxwell.Multipart.new_boundary
    name = "test_name"
    bin = "test_binary"
    extra_headers = [{"Content-Type", "image/jpeg"}]
    # hackney = :hackney_multipart.encode_form([{name, bin, extra_headers}], boundary)
    {body, size} = Maxwell.Multipart.encode(boundary, [{name, bin, extra_headers}])
    body1 = "--#{boundary}\r\ncontent-length: 11\r\ncontent-type: image/jpeg\r\ncontent-disposition: form-data; name=\"test_name\"\r\n\r\ntest_binary\r\n--#{boundary}--\r\n"
    assert size == 207
    assert body1 == body

  end

  test "name binary extraheaders disposition" do
    boundary = Maxwell.Multipart.new_boundary
    name = "test_name"
    bin = "test_binary"
    extra_headers = [{"Content-Type", "image/jpeg"}]
    disposition = {"form-data", [{"name", "content"}, {"testname", name}]}
    # hackney = :hackney_multipart.encode_form([{name, bin, disposition, extra_headers}], boundary)
    {body, size} = Maxwell.Multipart.encode(boundary, [{name, bin, disposition, extra_headers}])
    body1 = "--#{boundary}\r\ncontent-length: 11\r\ncontent-type: image/jpeg\r\ncontent-disposition: form-data; name=content; testname=test_name\r\n\r\ntest_binary\r\n--#{boundary}--\r\n"
    assert size == 223
    assert body1 == body

  end

  test "encode without boundary" do
    file_path = "test/maxwell/multipart_test_file.sh"
    {_body, size} = Maxwell.Multipart.encode([{:file, file_path}])
    assert size == 279
  end

  test "file disposition extra_headers stream len" do
    boundary = Maxwell.Multipart.new_boundary
    extra_headers = [{"Content-Type", "image/jpeg"}]
    file_path = "test/maxwell/multipart_test_file.sh"
    disposition = {"form-data", [{"name", "content"}]}
    size = Maxwell.Multipart.len_mp_stream(boundary, [{:file, file_path, disposition, extra_headers}])
    assert size == 239
  end

  test "mp_mixed stream len" do
    boundary = Maxwell.Multipart.new_boundary
    mixed_boundary = Maxwell.Multipart.new_boundary
    size = Maxwell.Multipart.len_mp_stream(boundary, [{:mp_mixed, "test", mixed_boundary}])
    assert size == 279
  end

  test "mp_mixed_eof stream len" do
    boundary = Maxwell.Multipart.new_boundary
    mixed_boundary = Maxwell.Multipart.new_boundary
    size = Maxwell.Multipart.len_mp_stream(boundary, [{:mp_mixed_eof, mixed_boundary}])
    assert size == 100
  end

  test "name binary stream len" do
    boundary = Maxwell.Multipart.new_boundary
    name = "test_name"
    bin = "test_binary"
    size = Maxwell.Multipart.len_mp_stream(boundary, [{name, bin}])
    assert size == 221
  end

  test "name binary extra_headers stream len" do
    boundary = Maxwell.Multipart.new_boundary
    name = "test_name"
    bin = "test_binary"
    extra_headers = [{"Content-Type", "image/jpeg"}]
    size = Maxwell.Multipart.len_mp_stream(boundary, [{name, bin, extra_headers}])
    assert size == 207
  end

  test "name binary disposition extra_headers stream len" do
    boundary = Maxwell.Multipart.new_boundary
    name = "test_name"
    bin = "test_binary"
    extra_headers = [{"Content-Type", "image/jpeg"}]
    disposition = {"form-data", [{"name", "content"}, {"testname", name}]}
    size = Maxwell.Multipart.len_mp_stream(boundary, [{name, bin, disposition, extra_headers}])
    assert size == 223
  end

  test "extra_header accept atom" do
    boundary = Maxwell.Multipart.new_boundary
    file_path = "test/maxwell/multipart_test_file.sh"
    extra_headers = [{"Content-Type", "image/jpeg"|> String.to_atom}]
    {body, size} = Maxwell.Multipart.encode(boundary, [{:file, file_path, extra_headers}])
    # hackney = :hackney_multipart.encode_form([{:file, file_path, extra_headers}], boundary)
    assert size == 273
    assert String.starts_with?(body, "--" <> boundary) == true
    assert String.ends_with?(body, boundary <> "--\r\n") == true
    assert String.replace(body, boundary, "") == "--\r\ncontent-length: 47\r\ncontent-disposition: form-data; name=\"file\"; filename=\"multipart_test_file.sh\"\r\ncontent-type: image/jpeg\r\n\r\n#!/usr/bin/env bash\necho \"test multipart file\"\n\r\n----\r\n"
  end

  test "extra_header accept list" do
    boundary = Maxwell.Multipart.new_boundary
    file_path = "test/maxwell/multipart_test_file.sh"
    extra_headers = [{"Content-Type", 'image/jpeg'}]
    {body, size} = Maxwell.Multipart.encode(boundary, [{:file, file_path, extra_headers}])
    # hackney = :hackney_multipart.encode_form([{:file, file_path, extra_headers}], boundary)
    assert size == 273
    assert String.starts_with?(body, "--" <> boundary) == true
    assert String.ends_with?(body, boundary <> "--\r\n") == true
    assert String.replace(body, boundary, "") == "--\r\ncontent-length: 47\r\ncontent-disposition: form-data; name=\"file\"; filename=\"multipart_test_file.sh\"\r\ncontent-type: image/jpeg\r\n\r\n#!/usr/bin/env bash\necho \"test multipart file\"\n\r\n----\r\n"
  end

  test "extra_header accept integer" do
    boundary = Maxwell.Multipart.new_boundary
    file_path = "test/maxwell/multipart_test_file.sh"
    extra_headers = [{"integer", 12}]
    {body, size} = Maxwell.Multipart.encode(boundary, [{:file, file_path, extra_headers}])
    # hackney = :hackney_multipart.encode_form([{:file, file_path, extra_headers}], boundary)
    assert size == 292
    assert String.starts_with?(body, "--" <> boundary) == true
    assert String.ends_with?(body, boundary <> "--\r\n") == true
    assert String.replace(body, boundary, "") == "--\r\ninteger: 12\r\ncontent-length: 47\r\ncontent-disposition: form-data; name=\"file\"; filename=\"multipart_test_file.sh\"\r\ncontent-type: application/x-sh\r\n\r\n#!/usr/bin/env bash\necho \"test multipart file\"\n\r\n----\r\n"
  end

end
