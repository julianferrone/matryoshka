defmodule Matryoshka.Impl.LogStore do
  @moduledoc """
  A log-file based storage implementation for the `Matryoshka.Storage`
  protocol.

  This store persists put and delete requests as logs on disk.
  """
  alias Matryoshka.Impl.LogStore.Deserialize
  alias Matryoshka.Impl.LogStore.Serialize
  alias Matryoshka.Storage

  @enforce_keys [:reader, :writer, :index]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          reader: File.io_device(),
          writer: File.io_device(),
          index: map()
        }

  def log_store(log_filepath) do
    {:ok, writer} = File.open(log_filepath, [:binary, :write])
    {:ok, reader} = File.open(log_filepath, [:binary, :read])
    %__MODULE__{reader: reader, writer: writer, index: Map.new()}
  end

  defimpl Storage do
    def fetch(store, ref) do
      {position, size} = Map.get(store.index, ref)

      case size do
        nil -> {:error, {:no_ref, ref}}

        nonzero ->
          case Deserialize.get_value(store.reader, position, nonzero) do
            {:ok, value} -> {:ok, value}
            :eof -> {:error, :eof}
            {:error, reason} -> {:error, reason}
          end
      end
    end

    def get(store, ref) do
      {position, size} = Map.get(store.index, ref)

      case size do
        nil ->
          nil

        nonzero ->
          case Deserialize.get_value(store.reader, position, nonzero) do
            {:ok, value} -> value
            _other -> nil
          end
      end
    end

    def put(store, ref, value) do
      {position, size} = Serialize.append_write_log_line(store.writer, ref, value)
      index = Map.put(store.index, ref, {position, size})
      %{store | index: index}
    end

    def delete(store, ref) do
      {position, size} = Serialize.append_delete_log_line(store.writer, ref)
      index = Map.put(store.index, ref, {position, size})
      %{store | index: index}
    end
  end
end
