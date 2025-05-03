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

  def bits_to_bytes(bits) do
    bits / 8
  end

  def read_big_unsigned_integer(fd, int_size) do
    number_bytes = bits_to_bytes(int_size)
    bytes = IO.binread(fd, number_bytes)
    <<int::big-unsigned-integer-size(int_size)>> = bytes
    int
  end

  def read_atom(fd) do
    atom_size = Encoding.atom_size()
    bytes = IO.binread(fd, atom_size)
    <<binary_atom::binary-size(atom_size)>> = bytes
    binary_to_term(binary_atom)
  end

  def read_log_line(fd) do
    _timestamp = read_big_unsigned_integer(fd, Encoding.timestamp_size())
    line_kind = read_atom(fd)
    atom_write = Encoding.atom_write()
    atom_delete = Encoding.atom_delete()

    case line_kind do
      ^atom_write -> read_write_line(fd)
      ^atom_delete -> read_delete_line(fd)
      _ -> {:err, {:no_line_kind, line_kind}}
    end
  end

  def read_write_line(fd) do
    key_size = read_big_unsigned_integer(fd, Encoding.key_size())
    value_size = read_big_unsigned_integer(fd, Encoding.value_size())

    key =
      IO.binread(fd, key_size)
      |> binary_to_term()

    value =
      IO.binread(fd, value_size)
      |> binary_to_term()

    {:ok, {Encoding.atom_write(), key, value}}
  end

  def read_delete_line(fd) do
    key_size = read_big_unsigned_integer(fd, Encoding.key_size())

    key =
      IO.binread(fd, key_size)
      |> binary_to_term()

    {:ok, {Encoding.atom_delete(), key}}
  end
end
