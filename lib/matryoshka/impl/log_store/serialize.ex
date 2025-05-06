defmodule Matryoshka.Impl.LogStore.Serialize do
  alias Matryoshka.Impl.LogStore.Encoding
  import :erlang, only: [term_to_binary: 1]

  # ------------------------ Timestamp -----------------------

  def binary_timestamp() do
    timestamp = System.system_time(Encoding.time_unit())
    <<timestamp::big-unsigned-integer-size(Encoding.timestamp_bitsize())>>
  end

  # ----------------------- Formatting -----------------------

  def format_write_log_line(key, value) do
    {key_size, key_size_data, key} = pack_key(key)
    {value_size, value_size_data, value} = pack_value(value)

    line =
      Enum.join([
        Encoding.atom_write_binary(),
        key_size_data,
        value_size_data,
        key,
        value
      ])

    line_size = Encoding.write_entry_pre_value_size(key_size)

    {prepend_timestamp(line), line_size, value_size}
  end

  def format_delete_log_line(key) do
    {key_size, key_size_data, key} = pack_key(key)

    line =
      Enum.join([
        Encoding.atom_delete_binary(),
        key_size_data,
        key
      ])

    line_size = Encoding.delete_entry_size(key_size)

    # Tuple in the form of the line, the relative offset of the value in the file,
    # and the value size. Because we deleted the value, we can just
    # notice that there's 0 bytes to read and say that this value was deleted
    {prepend_timestamp(line), line_size, nil}
  end

  def prepend_timestamp(data) when is_binary(data) do
    timestamp = binary_timestamp()
    timestamp <> data
  end

  def pack_term(term, int_size) do
    binary = term |> term_to_binary()
    size = byte_size(binary)
    size_data = <<size::big-unsigned-integer-size(int_size)>>
    {size, size_data, binary}
  end

  def pack_key(key), do: pack_term(key, Encoding.key_bitsize())

  def pack_value(value), do: pack_term(value, Encoding.value_bitsize())

  # ------------------- Writing to Log File ------------------

  def append_write_log_line(fd, key, value) do
    {line, relative_offset, value_size} = format_write_log_line(key, value)
    IO.binwrite(fd, line)
    {relative_offset, value_size}
  end

  def append_delete_log_line(fd, key) do
    {line, relative_offset, value_size} = format_delete_log_line(key)
    IO.binwrite(fd, line)
    {relative_offset, value_size}
  end
end
