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

  @doc """
  Opens a log file, either loading its offset index or creating a new one if
  the file doesn't exist.

  The function attempts to open the log file at the given `log_filepath`.

  If the file exists, it loads the offset index using `Deserialize.load_offsets/1`
  and opens the file for both reading and writing. If the file doesn't exist,
  it creates a new index and opens the file for both reading and writing.

  Returns a `%__MODULE__{}` struct containing the following:
    - `reader`: The file descriptor for reading from the log file.
    - `writer`: The file descriptor for writing to the log file.
    - `index`: A map representing the offset index of the log file.

  If the log file doesn't exist, the index is initialized as an empty map.
  """
  def log_store(log_filepath) do
    {reader, writer, index} =
      case File.open(log_filepath, [:binary, :read]) do
        {:ok, reader} ->
          index = Deserialize.load_offsets(reader)
          {:ok, writer} = File.open(log_filepath, [:binary, :append])
          {reader, writer, index}

        {:error, _reason} ->
          {:ok, writer} = File.open(log_filepath, [:binary, :write])
          {:ok, reader} = File.open(log_filepath, [:binary, :read])
          index = Map.new()
          {reader, writer, index}
      end

    %__MODULE__{reader: reader, writer: writer, index: index}
  end

  defimpl Storage do
    def fetch(store, ref) do
      value =
        with {:index, {:ok, {offset, size}}} when not is_nil(size) <-
               {:index, Map.fetch(store.index, ref)},
             {:store, {:ok, value}} <- {:store, Deserialize.get_value(store.reader, offset, size)} do
          value
        else
          {:index, :error} -> {:error, {:no_ref, ref}}
          {:index, {:ok, {_position, nil}}} -> {:error, {:no_ref, ref}}
          {:store, {:error, reason}} -> {:error, reason}
          {:store, :eof} -> {:error, :eof}
        end

      {store, value}
    end

    def get(store, ref) do
      value =
        with {:ok, {offset, size}} when not is_nil(size) <- Map.fetch(store.index, ref),
             {:ok, value} <- Deserialize.get_value(store.reader, offset, size) do
          value
        else
          _ -> nil
        end

      {store, value}
    end

    def put(store, ref, value) do
      {position, size} = Serialize.append_write_log_entry(store.writer, ref, value)

      index = Map.put(store.index, ref, {position, size})
      %{store | index: index}
    end

    def delete(store, ref) do
      {position, size} = Serialize.append_delete_log_entry(store.writer, ref)
      index = Map.put(store.index, ref, {position, size})
      %{store | index: index}
    end
  end
end
