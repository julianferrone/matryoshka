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
    {reader, writer, index} = case File.open(log_filepath, [:binary, :read]) do
      {:ok, reader} ->
        index = Deserialize.load_offsets(reader)
        {:ok, writer} = File.open(log_filepath, [:binary, :write])
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
