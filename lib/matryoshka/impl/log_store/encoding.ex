defmodule Matryoshka.Impl.LogStore.Encoding do
  # Timestamps are stored in a 64-bit unsigned int
  @timestamp_size 64
  def timestamp_size, do: @timestamp_size

  # Maximum key length is 2^16 bytes, ~66 kB
  @key_size 16
  def key_size, do: @key_size

  # Maximum value length is 2^32 bytes, ~4.3 GB
  @value_size 32
  def value_size, do: @value_size

  # Timestamps in log files have millisecond precision
  @time_unit :millisecond
  def time_unit, do: @time_unit

  # We're using single-letter atoms to represent write segments vs delete
  # segments in the log file. Single-letter atoms have a length of 4 after
  # converting them to binary with :erlang.term_to_binary/1.
  @atom_size 4
  def atom_size, do: @atom_size

  @atom_write :w
  def atom_write, do: @atom_write

  def atom_write_binary, do: :erlang.term_to_binary(@atom_write)

  @atom_delete :d
  def atom_delete, do: @atom_delete

  def atom_delete_binary, do: :erlang.term_to_binary(@atom_delete)
end
