defmodule Matryoshka.Impl.LogStore do
  @moduledoc """
  A log-file based storage implementation for the `Matryoshka.Storage`
  protocol.

  This store persists put and delete requests as logs on disk.
  """
  import :erlang, only: [binary_to_term: 1, term_to_binary: 1]
  alias Matryoshka.Reference
  alias Matryoshka.Storage

  @enforce_keys [:log_filepath, :index]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          log_filepath: Path.t(),
          index: map()
        }

  def log_store(log_filepath) do
    %__MODULE__{log_filepath: log_filepath, index: Map.new()}
  end

  alias __MODULE__

  # Timestamps are stored in a 64-bit unsigned int
  @timestamp_size 64
  def timestamp_size, do: @timestamp_size

  # Maximum key length is 2^16 bytes, ~66 kB
  @key_size 16
  def key_size, do: @key_size

  # Maximum value length is 2^32 bytes, ~4.3 GB
  @value_size 32
  def value_size, do: @value_size

  defmodule Deserialize do
  end

  defmodule Serialize do
    def binary_timestamp() do
      timestamp = System.system_time(:millisecond)
      <<timestamp::big-unsigned-integer-size(LogStore.timestamp_size())>>
    end

    def format_log_line(data) when is_binary(data) do
      timestamp = binary_timestamp()
      timestamp <> data
    end

    def write_log_line(store, data) when is_binary(data) do
      with {:ok, file} <- File.open(store.log_filepath, [:binary, :append]) do
        line = format_log_line(data)
        IO.binwrite(file, line)
      end
    end

    @spec pack_term(term(), integer()) :: {binary(), binary()}
    def pack_term(term, int_size) do
      binary = term |> term_to_binary()
      size_data = <<byte_size(binary)::big-unsigned-integer-size(int_size)>>
      {size_data, binary}
    end

    def pack_key(key), do: pack_term(key, LogStore.key_size())

    def pack_value(value), do: pack_term(value, LogStore.value_size())
  end

  defimpl Storage do
    def put(store, ref, value) do
      {key_size, key} = LogStore.Serialize.pack_key(ref)
      {value_size, value} = LogStore.Serialize.pack_value(value)

      line =
        Enum.join([
          term_to_binary(:w),
          key_size,
          value_size,
          key,
          value
        ])

      LogStore.Serialize.write_log_line(store, line)
      store
    end

    def delete(store, ref) do
      {key_size, key} = LogStore.Serialize.pack_term(ref)

      line =
        Enum.join([
          term_to_binary(:d),
          key_size,
          key
        ])

      LogStore.Serialize.write_log_line(store, line)
      store
    end
  end
end
