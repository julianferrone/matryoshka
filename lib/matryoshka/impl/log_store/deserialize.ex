defmodule Matryoshka.Impl.LogStore.Deserialize do
  alias Matryoshka.Impl.LogStore.Encoding
  import :erlang, only: [binary_to_term: 1]

  # -------------------- Parsing Binaries --------------------

  def parse_timestamp(bin_timestamp) do
    timestamp_size = Encoding.timestamp_size()
    <<int_timestamp::big-unsigned-integer-size(timestamp_size)>> = bin_timestamp
    DateTime.from_unix(int_timestamp, Encoding.time_unit())
  end

  def parse_key_size(bin_key_size) do
    key_size = Encoding.key_size()
    <<int_key_size::big-unsigned-integer-size(key_size)>> = bin_key_size
    int_key_size
  end

  def parse_value_size(bin_value_size) do
    value_size = Encoding.value_size()
    <<int_value_size::big-unsigned-integer-size(value_size)>> = bin_value_size
    int_value_size
  end

  # -------------------- Parse Whole Line --------------------

  def parse_log_line(line) do
    timestamp_size = Encoding.timestamp_size()
    atom_size = Encoding.atom_size()

    <<_timestamp::big-unsigned-integer-size(timestamp_size), rest::binary>> = line
    <<binary_atom::binary-size(atom_size), rest::binary>> = rest

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
    key_size = Encoding.key_size()
    value_size = Encoding.value_size()

    <<int_key_size::big-unsigned-integer-size(key_size), rest::binary>> = line
    <<int_value_size::big-unsigned-integer-size(value_size), rest::binary>> = rest

    <<bin_key::binary-size(int_key_size), rest::binary>> = rest
    <<bin_value::binary-size(int_value_size), _rest::binary>> = rest

    key = binary_to_term(bin_key)
    value = binary_to_term(bin_value)
    {:ok, {Encoding.atom_write(), key, value}}
  end

  def parse_delete_line(line) do
    key_size = Encoding.key_size()

    <<int_key_size::big-unsigned-integer-size(key_size), rest::binary>> = line

    <<bin_key::binary-size(int_key_size), _rest::binary>> = rest

    key = binary_to_term(bin_key)
    {:ok, {Encoding.atom_delete(), key}}
  end

  # ------------------ Reading from Log File -----------------

  # ....................... IO Helpers .......................

  def handle_io_result(:eof, _fun), do: :eof
  def handle_io_result({:error, reason}, _fun), do: {:error, reason}
  def handle_io_result(bytes, fun), do: {:ok, fun.(bytes)}

  def binread_then_map(fd, number_bytes, fun) do
    bytes = IO.binread(fd, number_bytes)
    handle_io_result(bytes, fun)
  end

  def bits_to_bytes(bits), do: div(bits, 8)

  # .................. Reading Elixir types ..................

  def read_big_unsigned_integer(fd, int_size) do
    number_bytes = bits_to_bytes(int_size)

    binread_then_map(fd, number_bytes, fn bytes ->
      <<int::big-unsigned-integer-size(int_size)>> = bytes
      int
    end)
  end

  def read_atom(fd) do
    atom_size = Encoding.atom_size()

    binread_then_map(
      fd,
      atom_size,
      fn bytes ->
        <<binary_atom::binary-size(atom_size)>> = bytes
        atom = binary_to_term(binary_atom)
        atom
      end
    )
  end

  def read_timestamp(fd) do
    timestamp_size = Encoding.timestamp_size()
    timestamp_int = read_big_unsigned_integer(fd, timestamp_size)

    handle_io_result(
      timestamp_int,
      fn ts ->
        DateTime.from_unix(
          ts,
          Encoding.time_unit()
        )
      end
    )
  end

  # .................... Reading Log Lines ...................

  def read_log_line(fd) do
    _timestamp = read_timestamp(fd)
    line_kind = read_atom(fd)
    atom_write = Encoding.atom_write()
    atom_delete = Encoding.atom_delete()

    case line_kind do
      {:ok, ^atom_write} -> read_write_line(fd)
      {:ok, ^atom_delete} -> read_delete_line(fd)
      {:ok, atom} -> {:erro, {:no_line_kind, atom}}
      other -> other
    end
  end

  def read_write_line(fd) do
    key_size = read_big_unsigned_integer(fd, Encoding.key_size())
    value_size = read_big_unsigned_integer(fd, Encoding.value_size())

    with {:ok, key} <-
           binread_then_map(fd, key_size, &binary_to_term/1),
         {:ok, value} <-
           binread_then_map(fd, value_size, &binary_to_term/1) do
      {:ok, {Encoding.atom_write(), key, value}}
    else
      error -> error
    end
  end

  def read_delete_line(fd) do
    key_size = read_big_unsigned_integer(fd, Encoding.key_size())

    with {:ok, key} <-
           binread_then_map(fd, key_size, &binary_to_term/1) do
      {:ok, {Encoding.atom_delete(), key}}
    else
      error -> error
    end
  end
end
