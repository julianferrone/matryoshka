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
    index: Map.t()
  }

  def log_store(log_filepath) do
    %__MODULE__{log_filepath: log_filepath, index: Map.new()}
  end

  alias __MODULE__

  def write_log_line(store, data) when is_binary(data) do
    with {:ok, file} <- File.open(store.log_filepath, [:binary, :append]) do
      timestamp = System.system_time(:nanosecond) |> term_to_binary()
      line = timestamp <> data
      IO.binwrite(file, line)
    end
  end

  @spec pack_term(term()) :: {binary(), binary()}
  def pack_term(term) do
    binary = term |> term_to_binary()
    size = binary |> byte_size() |> term_to_binary()
    {size, binary}
  end

  defimpl Storage do
    def put(store, ref, value) do
      {key_size, key} = LogStore.pack_term(ref)
      {value_size, value} = LogStore.pack_term(value)
      line = Enum.join([
        term_to_binary(:w),
        key_size,
        value_size,
        key,
        value
      ])
      LogStore.write_log_line(store, line)
      store
    end

    def delete(store, ref, value) do
      {key_size, key} = LogStore.pack_term(ref)
      line = Enum.join([
        term_to_binary(:d),
        key_size,
        key,
      ])
      LogStore.write_log_line(store, line)
      store
    end
  end
end
