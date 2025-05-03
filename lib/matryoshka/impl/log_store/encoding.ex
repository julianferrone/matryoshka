defmodule Matryoshka.Impl.LogStore.Encoding do
  # Timestamps are stored in a 64-bit unsigned int
  @timestamp_bitsize 64
  def timestamp_bitsize, do: @timestamp_bitsize

  # Maximum key length is 2^16 bits, ~66 kB
  @key_bitsize 16
  def key_bitsize, do: @key_bitsize

  # Maximum value length is 2^32 bits, ~4.3 GB
  @value_bitsize 32
  def value_bitsize, do: @value_bitsize

  # Timestamps in log files have millisecond precision
  @time_unit :millisecond
  def time_unit, do: @time_unit

  # We're using single-letter atoms to represent write segments vs delete
  # segments in the log file. Single-letter atoms have a length of 4 after
  # converting them to binary with :erlang.term_to_binary/1.
  @atom_bytesize 4
  def atom_bytesize, do: @atom_bytesize

  @atom_write :w
  def atom_write, do: @atom_write

  def atom_write_binary, do: :erlang.term_to_binary(@atom_write)

  @atom_delete :d
  def atom_delete, do: @atom_delete

  def atom_delete_binary, do: :erlang.term_to_binary(@atom_delete)

  def bits_to_bytes(bits), do: div(bits, 8)

  def relative_offset(key_size) do
    Enum.sum([
      bits_to_bytes(@timestamp_bitsize),
      atom_bytesize(),
      bits_to_bytes(@key_bitsize),
      key_size
    ])
  end

  def relative_offset(key_size, value_size) do
    Enum.sum([
      relative_offset(key_size),
      bits_to_bytes(@value_bitsize),
      value_size
    ])
  end
end
