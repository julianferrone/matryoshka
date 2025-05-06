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
      value = case Map.fetch(store.index, ref) do
        :error -> {:error, {:no_ref, ref}}
        {:ok, {_position, nil}} -> {:error, {:no_ref, ref}}
        {:ok, {position, size}} ->
          case Deserialize.get_value(store.reader, position, size) do
            {:ok, value} -> value
            {:error, reason} -> {:error, reason}
            :eof -> {:error, :eof}
          end
        end
      {store, value}
      end

    def get(store, ref) do
      value = case Map.fetch(store.index, ref) do
        :error ->

          nil
        {:ok, {_position, nil}} = given1 ->

          nil
        {:ok, {offset, size}} = given2 ->

          case Deserialize.get_value(store.reader, offset, size) do
            {:ok, value} = given3 ->

              value
            other ->

              nil
          end
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
