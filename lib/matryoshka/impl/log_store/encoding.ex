defmodule Matryoshka.Impl.LogStore.Encoding do
  # Timestamps are stored in a 64-bit unsigned int
  @timestamp_bitsize 64
  @doc """
  Returns the number of bits used to store timestamps in the log format.

  Timestamps are stored as 64-bit unsigned integers.
  """
  def timestamp_bitsize, do: @timestamp_bitsize

  # Maximum key length is 2^16 bits, ~66 kB
  @key_bitsize 16
  @doc """
  Returns the number of bits allocated for encoding key sizes.

  This allows a maximum key size of 2^16 bits (~66 KB).
  """
  def key_bitsize, do: @key_bitsize

  # Maximum value length is 2^32 bits, ~4.3 GB
  @value_bitsize 32
  @doc """
  Returns the number of bits allocated for encoding value sizes.

  This allows a maximum value size of 2^32 bits (~4.3 GB).
  """
  def value_bitsize, do: @value_bitsize

  # Timestamps in log files have millisecond precision
  @time_unit :millisecond

  @doc """
  Returns the unit of time used for timestamps in the log files.

  Timestamps have millisecond precision.
  """
  def time_unit, do: @time_unit

  # We're using single-letter atoms to represent write segments vs delete
  # segments in the log file. Single-letter atoms have a length of 4 after
  # converting them to binary with :erlang.term_to_binary/1.
  @atom_bytesize 4
  @doc """
  Returns the size in bytes of single-letter atoms when serialized with `:erlang.term_to_binary/1`.

  This value is used to account for the space needed to store log operation tags like `:w` and `:d`.
  """
  def atom_bytesize, do: @atom_bytesize

  @atom_write :w
  @doc """
  Returns the atom used to represent write operations in the log format.
  """
  def atom_write, do: @atom_write

  @doc """
  Returns the binary representation of the write atom (`:w`) used in the log format.

  Serialized with `:erlang.term_to_binary/1`.
  """
  def atom_write_binary, do: :erlang.term_to_binary(@atom_write)

  @atom_delete :d
  @doc """
  Returns the atom used to represent delete operations in the log format.
  """
  def atom_delete, do: @atom_delete

  @doc """
  Returns the binary representation of the delete atom (`:d`) used in the log format.

  Serialized with `:erlang.term_to_binary/1`.
  """
  def atom_delete_binary, do: :erlang.term_to_binary(@atom_delete)

  @doc """
  Converts a bit size to a byte size by dividing by 8.

  Useful for translating field sizes specified in bits to actual byte sizes.
  """
  def bits_to_bytes(bits), do: div(bits, 8)

  @doc """
  Calculates the total size in bytes of a delete log entry.

  A delete entry includes:
  - A 64-bit timestamp
  - A 4-byte delete atom (i.e., `:d`)
  - A 16-bit key size indicator
  - The key itself

  ## Parameters

    - `key_size`: Size of the key in bytes.

  ## Returns

    - Total size of the delete entry in bytes.
  """
  def delete_entry_size(key_size) do
    Enum.sum([
      bits_to_bytes(@timestamp_bitsize),
      atom_bytesize(),
      bits_to_bytes(@key_bitsize),
      key_size
    ])
  end

  @doc """
  Calculates the total size in bytes of a write log entry.

  A write entry includes:
  - A 64-bit timestamp
  - A 4-byte write atom (i.e., `:w`)
  - A 16-bit key size indicator
  - A 32-bit value size indicator
  - The key
  - The value

  ## Parameters

    - `key_size`: Size of the key in bytes.
    - `value_size`: Size of the value in bytes.

  ## Returns

    - Total size of the write entry in bytes.
  """
  def write_entry_size(key_size, value_size) do
    Enum.sum([
      bits_to_bytes(@timestamp_bitsize),
      atom_bytesize(),
      bits_to_bytes(@key_bitsize),
      bits_to_bytes(@value_bitsize),
      key_size,
      value_size
    ])
  end

  @doc """
  Calculates the size in bytes of the header portion of a write entry,
  up to (but not including) the value.

  This includes:
  - A 64-bit timestamp
  - A 4-byte write atom (e.g., `:w`)
  - A 16-bit key size indicator
  - A 32-bit value size indicator
  - The key

  ## Parameters

    - `key_size`: Size of the key in bytes.

  ## Returns

    - Size of the write entry up to the value field, in bytes.
  """
  def write_entry_pre_value_size(key_size) do
    Enum.sum([
      bits_to_bytes(@timestamp_bitsize),
      atom_bytesize(),
      bits_to_bytes(@key_bitsize),
      bits_to_bytes(@value_bitsize),
      key_size
    ])
  end
end
