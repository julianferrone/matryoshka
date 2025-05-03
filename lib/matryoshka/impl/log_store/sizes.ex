defmodule Matryoshka.Impl.LogStore.Sizes do
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
end
