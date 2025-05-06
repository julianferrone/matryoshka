defmodule Matryoshka.Impl.LogStore.Deserialize do
  alias Matryoshka.Impl.LogStore.Encoding
  import :erlang, only: [binary_to_term: 1]

  # ____________________ Parsing Binaries ____________________

  def parse_timestamp(bin_timestamp) do
    timestamp_bitsize = Encoding.timestamp_bitsize()
    <<int_timestamp::big-unsigned-integer-size(timestamp_bitsize)>> = bin_timestamp
    DateTime.from_unix(int_timestamp, Encoding.time_unit())
  end

  def parse_key_size(bin_key_size) do
    key_bitsize = Encoding.key_bitsize()
    <<int_key_size::big-unsigned-integer-size(key_bitsize)>> = bin_key_size
    int_key_size
  end

  def parse_value_size(bin_value_size) do
    value_bitsize = Encoding.value_bitsize()
    <<int_value_size::big-unsigned-integer-size(value_bitsize)>> = bin_value_size
    int_value_size
  end

  # ___________________ Parsing Whole Lines __________________

  def parse_log_line(line) do
    timestamp_bitsize = Encoding.timestamp_bitsize()
    atom_bytesize = Encoding.atom_bytesize()

    <<_timestamp::big-unsigned-integer-size(timestamp_bitsize), rest::binary>> = line
    <<binary_atom::binary-size(atom_bytesize), rest::binary>> = rest

    atom = binary_to_term(binary_atom)
    atom_write = Encoding.atom_write()
    atom_delete = Encoding.atom_delete()

    case atom do
      ^atom_write -> parse_write_line(rest)
      ^atom_delete -> parse_delete_line(rest)
      _ -> {:err, {:no_line_kind, atom}}
    end
  end

  def parse_write_line(line) do
    key_bitsize = Encoding.key_bitsize()
    value_bitsize = Encoding.value_bitsize()

    <<int_key_size::big-unsigned-integer-size(key_bitsize), rest::binary>> = line
    <<int_value_size::big-unsigned-integer-size(value_bitsize), rest::binary>> = rest

    <<bin_key::binary-size(int_key_size), rest::binary>> = rest
    <<bin_value::binary-size(int_value_size), _rest::binary>> = rest

    key = binary_to_term(bin_key)
    value = binary_to_term(bin_value)
    {:ok, {Encoding.atom_write(), key, value}}
  end

  def parse_delete_line(line) do
    key_bitsize = Encoding.key_bitsize()

    <<int_key_size::big-unsigned-integer-size(key_bitsize), rest::binary>> = line

    <<bin_key::binary-size(int_key_size), _rest::binary>> = rest

    key = binary_to_term(bin_key)
    {:ok, {Encoding.atom_delete(), key}}
  end

  # __________________ Reading from Log File _________________

  # ----------------------- IO Helpers -----------------------

  def handle_io_result(:eof, _fun), do: :eof
  def handle_io_result({:error, reason}, _fun), do: {:error, reason}
  def handle_io_result(bytes, fun), do: {:ok, fun.(bytes)}

  def binread_then_map(fd, number_bytes, fun) do
    bytes = IO.binread(fd, number_bytes)
    handle_io_result(bytes, fun)
  end

  # ------------------ Reading Elixir Types ------------------

  def read_big_unsigned_integer(fd, int_size) do
    number_bytes = Encoding.bits_to_bytes(int_size)

    binread_then_map(fd, number_bytes, fn bytes ->
      <<int::big-unsigned-integer-size(int_size)>> = bytes
      int
    end)
  end

  def read_atom(fd) do
    atom_bytesize = Encoding.atom_bytesize()

    binread_then_map(
      fd,
      atom_bytesize,
      fn bytes ->
        <<binary_atom::binary-size(atom_bytesize)>> = bytes
        atom = binary_to_term(binary_atom)
        atom
      end
    )
  end

  def read_timestamp(fd) do
    timestamp_bitsize = Encoding.timestamp_bitsize()

    with {:ok, timestamp_int} <- read_big_unsigned_integer(fd, timestamp_bitsize) do
      DateTime.from_unix(timestamp_int, Encoding.time_unit())
    else
      other -> other
    end
  end

  # -------------------- Reading Log Lines -------------------

  # .................... Read Entire Line ....................

  def read_log_line(fd) do
    _timestamp = read_timestamp(fd)
    line_kind = read_atom(fd)
    atom_write = Encoding.atom_write()
    atom_delete = Encoding.atom_delete()

    case line_kind do
      {:ok, ^atom_write} -> read_write_line(fd)
      {:ok, ^atom_delete} -> read_delete_line(fd)
      {:ok, atom} -> {:error, {:no_line_kind, atom}}
      other -> other
    end
  end

  def read_write_line(fd) do
    with {:ok, key_size} <- read_big_unsigned_integer(fd, Encoding.key_bitsize()),
         {:ok, value_size} = read_big_unsigned_integer(fd, Encoding.value_bitsize()),
         {:ok, key} <-
           binread_then_map(fd, key_size, &binary_to_term/1),
         {:ok, value} <-
           binread_then_map(fd, value_size, &binary_to_term/1) do
      {:ok, {Encoding.atom_write(), key, value}}
    else
      error -> error
    end
  end

  def read_delete_line(fd) do
    with {:ok, key_size} <- read_big_unsigned_integer(fd, Encoding.key_bitsize()),
         {:ok, key} <-
           binread_then_map(fd, key_size, &binary_to_term/1) do
      {:ok, {Encoding.atom_delete(), key}}
    else
      error -> error
    end
  end

  # ............... Load Offsets and Value Size ..............

  def load_offsets(fd) do
    load_offsets(fd, Map.new(), 0)
  end

  def load_offsets(fd, offsets, current_offset) do
    :file.position(fd, current_offset)
    with {:ok, _timestamp} <- read_timestamp(fd),
         {:ok, line_kind} <- read_atom(fd),
         {:ok, {key, key_size, value_size}} <- load_offsets_line(fd, line_kind) do
      relative_offset_to_value =
        case value_size do
          nil ->
            Encoding.delete_entry_size(key_size)

          _nonzero ->
            Encoding.write_entry_pre_value_size(key_size)
        end

      relative_offset_to_end =
        case value_size do
          nil -> Encoding.delete_entry_size(key_size)
          value_size -> Encoding.write_entry_size(key_size, value_size)
        end

      value_offset =
        current_offset + relative_offset_to_value

      offsets = Map.put(offsets, key, {value_offset, value_size})

      absolute_offset =
        current_offset + relative_offset_to_end

      load_offsets(fd, offsets, absolute_offset)
    else
      :eof -> {offsets, current_offset}
    end
  end

  def load_offsets_line(fd, line_kind) do
    atom_write = Encoding.atom_write()
    atom_delete = Encoding.atom_delete()

    case line_kind do
      ^atom_write -> load_offsets_write_line(fd)
      ^atom_delete -> load_offsets_delete_line(fd)
      atom when is_atom(atom) -> {:error, {:no_lin_kind, atom}}
      other -> other
    end
  end

  def load_offsets_write_line(fd) do
    with {:ok, key_size} <- read_big_unsigned_integer(fd, Encoding.key_bitsize()),
         {:ok, value_size} <- read_big_unsigned_integer(fd, Encoding.value_bitsize()) do
      binread_then_map(fd, key_size, fn key_bin ->
        key = binary_to_term(key_bin)
        {key, key_size, value_size}
      end)
    end
  end

  def load_offsets_delete_line(fd) do
    key_size = read_big_unsigned_integer(fd, Encoding.key_bitsize())

    binread_then_map(fd, key_size, fn key_bin ->
      key = binary_to_term(key_bin)
      {key, key_size, nil}
    end)
  end

  # ------------------- Reading Whole File -------------------

  def get_index(log_filepath) do
    with {:ok, file} <- File.open(log_filepath, [:binary, :read]) do
      load_offsets(file)
    end
  end

  # ----------------- Read Value at Position -----------------

  def get_value(fd, offset, size) when not is_nil(size) do
    with {:ok, bin} <- :file.pread(fd, offset, size) do

      {:ok, binary_to_term(bin)}
    else
      other -> other
    end
  end
end
