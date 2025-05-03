defmodule Matryoshka.Impl.LogStore do
  @moduledoc """
  A log-file based storage implementation for the `Matryoshka.Storage`
  protocol.

  This store persists put and delete requests as logs on disk.
  """
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

  # defimpl Storage do
  #   def put(store, ref, value) do
  #     # {key_size, key} = LogStore.Serialize.pack_key(ref)
  #     # {value_size, value} = LogStore.Serialize.pack_value(value)

  #     # line =
  #     #   Enum.join([
  #     #     term_to_binary(:w),
  #     #     key_size,
  #     #     value_size,
  #     #     key,
  #     #     value
  #     #   ])

  #     # LogStore.Serialize.write_log_line(store, line)
  #     # store
  #   end

  #   def delete(store, ref) do
  #     # {key_size, key} = LogStore.Serialize.pack_term(ref)

  #     # line =
  #     #   Enum.join([
  #     #     term_to_binary(:d),
  #     #     key_size,
  #     #     key
  #     #   ])

  #     # LogStore.Serialize.write_log_line(store, line)
  #     # store
  #   end
  # end
end
