defmodule Matryoshka.Impl.LogStore.Serialize do
  alias Matryoshka.Impl.LogStore.Encoding
  import :erlang, only: [term_to_binary: 1]

  # ------------------------ Timestamp -----------------------

  def binary_timestamp() do
    timestamp = System.system_time(Encoding.time_unit)
    <<timestamp::big-unsigned-integer-size(Encoding.timestamp_size())>>
  end

  # ----------------------- Formatting -----------------------

  def format_write_log_line(key, value) do
    {key_size, key} = pack_key(key)
    {value_size, value} = pack_value(value)
    line = Enum.join([
      :w,
      key_size,
      value_size,
      key,
      value
    ])
    prepend_timestamp(line)
  end

  def format_delete_log_line(key) do
    {key_size, key} = pack_key(key)
    line = Enum.join([
      :d,
      key_size,
      key
    ])
    prepend_timestamp(line)
  end

  def prepend_timestamp(data) when is_binary(data) do
    timestamp = binary_timestamp()
    timestamp <> data
  end

  @spec pack_term(term(), integer()) :: {binary(), binary()}
  def pack_term(term, int_size) do
    binary = term |> term_to_binary()
    size_data = <<byte_size(binary)::big-unsigned-integer-size(int_size)>>
    {size_data, binary}
  end

  def pack_key(key), do: pack_term(key, Encoding.key_size())

  def pack_value(value), do: pack_term(value, Encoding.value_size())

  # ------------------- Writing to Log File ------------------

  # def write_log_line(store, data) when is_binary(data) do
  #   with {:ok, file} <- File.open(store.log_filepath, [:binary, :append]) do
  #     line = prepend_timestamp(data)
  #     IO.binwrite(file, line)
  #   end
  # end
end
