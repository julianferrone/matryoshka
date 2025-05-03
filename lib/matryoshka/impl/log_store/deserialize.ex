defmodule Matryoshka.Impl.LogStore.Deserialize do
  alias Matryoshka.Impl.LogStore.Sizes
  import :erlang, only: [binary_to_term: 1]

  def parse_timestamp(bin_timestamp) do
    timestamp_size = Sizes.timestamp_size()
    <<int_timestamp::big-unsigned-integer-size(timestamp_size)>> = bin_timestamp
    DateTime.from_unix(int_timestamp, :millisecond)
  end

  def parse_key_size(bin_key_size) do
    key_size = Sizes.key_size()
    <<int_key_size::big-unsigned-integer-size(key_size)>> = bin_key_size
    int_key_size
  end

  def parse_value_size(bin_value_size) do
    value_size = Sizes.value_size()
    <<int_value_size::big-unsigned-integer-size(value_size)>> = bin_value_size
    int_value_size
  end
end
