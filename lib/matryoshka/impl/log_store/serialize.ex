defmodule Matryoshka.Impl.LogStore.Serialize do
  alias Matryoshka.Impl.LogStore.Encoding
  import :erlang, only: [term_to_binary: 1]

  # ------------------------ Timestamp -----------------------

  @doc """
  Returns the current system time encoded as a binary.

  The timestamp is encoded as a big-endian unsigned integer using the bit size
  and time unit defined in the `LogStore.Encoding` module.

  ## Returns

    - A binary representing the current timestamp.
  """
  def binary_timestamp() do
    timestamp = System.system_time(Encoding.time_unit())
    <<timestamp::big-unsigned-integer-size(Encoding.timestamp_bitsize())>>
  end

  # ----------------------- Formatting -----------------------

  @doc """
  Formats a key-value pair as a binary log entry representing a write operation.

  Returns a tuple `{entry_binary, relative_offset_to_value, value_size}`, where:
    - `entry_binary` is the binary log entry with a prepended timestamp.
    - `relative_offset_to_value` is the number of bytes from the start of the
       entry to the start of the value.
    - `value_size` is the size of the value in bytes.
  """
  def format_write_log_entry(key, value) do
    {key_size, key_size_data, key} = pack_key(key)
    {value_size, value_size_data, value} = pack_value(value)

    entry =
      Enum.join([
        Encoding.atom_write_binary(),
        key_size_data,
        value_size_data,
        key,
        value
      ])

    entry_size = Encoding.write_entry_pre_value_size(key_size)

    {prepend_timestamp(entry), entry_size, value_size}
  end

  @doc """
  Formats a key as a binary log entry representing a delete operation.

  Returns a tuple `{entry_binary, relative_offset_to_value, nil}`, where:
    - `entry_binary` is the binary log entry with a prepended timestamp.
    - `relative_offset_to_value` is the number of bytes from the start of the
      entry to the (deleted) value position.
    - The third element is `nil`, indicating the value is deleted.
  """
  def format_delete_log_entry(key) do
    {key_size, key_size_data, key} = pack_key(key)

    entry =
      Enum.join([
        Encoding.atom_delete_binary(),
        key_size_data,
        key
      ])

    entry_size = Encoding.delete_entry_size(key_size)

    # Tuple in the form of the entry, the relative offset of the value in the file,
    # and the value size. Because we deleted the value, we can just
    # notice that there's 0 bytes to read and say that this value was deleted
    {prepend_timestamp(entry), entry_size, nil}
  end

  @doc """
  Prepends a binary-encoded timestamp to the given binary data.

  Used to timestamp log entries.
  """
  def prepend_timestamp(data) when is_binary(data) do
    timestamp = binary_timestamp()
    timestamp <> data
  end

  @doc """
  Packs a term into a binary representation with a size prefix of the given bit
  width.

  Returns a tuple `{size, size_data, binary_term}` where:
    - `size` is the byte size of the binary-encoded term.
    - `size_data` is the binary-encoded size using `int_size` bits.
    - `binary_term` is the binary representation of the term.
  """
  def pack_term(term, int_size) do
    binary = term |> term_to_binary()
    size = byte_size(binary)
    size_data = <<size::big-unsigned-integer-size(int_size)>>
    {size, size_data, binary}
  end

  @doc """
  Packs a key into a binary representation with a size prefix of the key's
  bit width.

  Uses `Encoding.key_bitsize()` to determine the bit size for the key.

  Returns a tuple `{size, size_data, binary_key}` where:
    - `size` is the byte size of the binary-encoded key.
    - `size_data` is the binary-encoded size using `Encoding.key_bitsize()` bits.
    - `binary_key` is the binary representation of the key.
  """
  def pack_key(key), do: pack_term(key, Encoding.key_bitsize())

  @doc """
  Packs a value into a binary representation with a size prefix of the value's bit width.

  Uses `Encoding.value_bitsize()` to determine the bit size for the value.

  Returns a tuple `{size, size_data, binary_value}` where:
    - `size` is the byte size of the binary-encoded value.
    - `size_data` is the binary-encoded size using `Encoding.value_bitsize()` bits.
    - `binary_value` is the binary representation of the value.
  """
  def pack_value(value), do: pack_term(value, Encoding.value_bitsize())

  # ------------------- Writing to Log File ------------------

  @doc """
  Appends a formatted write log entry to the file descriptor.

  Formats the given `key` and `value` into a write log entry and writes it to
  the file descriptor `fd`.

  Returns a tuple `{relative_offset, value_size}` where:
    - `relative_offset` is the offset from the start of the log entry to the
      value.
    - `value_size` is the size of the value in bytes.
  """
  def append_write_log_entry(fd, key, value) do
    {entry, relative_offset, value_size} = format_write_log_entry(key, value)
    IO.binwrite(fd, entry)
    {relative_offset, value_size}
  end

  @doc """
  Appends a formatted delete log entry to the file descriptor.

  Formats the given `key` into a delete log entry and writes it to the file
  descriptor `fd`.

  Returns a tuple `{relative_offset, value_size}` where:
    - `relative_offset` is the offset from the start of the log entry to the
      (deleted) value position.
    - `value_size` is `nil` because the value is deleted.
  """
  def append_delete_log_entry(fd, key) do
    {entry, relative_offset, value_size} = format_delete_log_entry(key)
    IO.binwrite(fd, entry)
    {relative_offset, value_size}
  end
end
