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
      _ -> {:err, {:wrong_atom, atom}}
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
end
