defmodule StorageCombinators.Impl.SwitchingStore do
  alias StorageCombinators.Impl.SwitchingStore
  alias StorageCombinators.Reference
  import StorageCombinators.StorageCombinators, only: [is_storage!: 1]

  @enforce_keys [:path_store_map]
  defstruct @enforce_keys

  @typedoc """
  A struct that implements the StorageCombinators.Storage protocol.
  """
  @type impl_storage :: any()

  @type t :: %__MODULE__{
          path_store_map: %{String.t() => impl_storage()}
        }

  @spec switching_store(%{String.t() => impl_storage()} | impl_storage()) :: SwitchingStore.t()
  def switching_store(path_store_map) when is_map(path_store_map) do
    Map.values(path_store_map)
    |> Enum.each(&is_storage!/1)

    %__MODULE__{
      path_store_map: path_store_map
    }
  end

  alias __MODULE__

  def split_reference(ref) do
    [path_head | path_tail] = Reference.path_segments(ref)

    case path_tail do
      [] -> {:error, {:ref_path_too_short, ref}}
      path -> {:ok, path_head, Enum.join(path, "/")}
    end
  end

  def choose_store(%SwitchingStore{path_store_map: path_store_map}, ref) do
    case split_reference(ref) do
      {:ok, first, _rest} -> Map.fetch(path_store_map, first)
      error -> error
    end
  end

  defimpl StorageCombinators.Storage do
    def fetch(%SwitchingStore{path_store_map: path_store_map} = store, ref) do
      with {:ok, sub_store} <- SwitchingStore.choose_store(store, ref),
           {:ok, first, rest_ref} = SwitchingStore.split_reference(ref) do
        {new_sub_store, value} = StorageCombinators.Storage.fetch(sub_store, rest_ref)
        new_path_store_map = Map.put(path_store_map, first, new_sub_store)
        new_store = SwitchingStore.switching_store(new_path_store_map)
        {new_store, value}
      else
        {:error, reason} -> {store, {:error, reason}}
      end
    end

    def get(%SwitchingStore{path_store_map: path_store_map} = store, ref) do
      with {:ok, sub_store} <- SwitchingStore.choose_store(store, ref),
           {:ok, first, rest_ref} = SwitchingStore.split_reference(ref) do
        {new_sub_store, value} = StorageCombinators.Storage.get(sub_store, rest_ref)
        new_path_store_map = Map.put(path_store_map, first, new_sub_store)
        new_store = SwitchingStore.switching_store(new_path_store_map)
        {new_store, value}
      else
        _ -> {store, nil}
      end
    end

    def put(%SwitchingStore{path_store_map: path_store_map} = store, ref, value) do
      with {:ok, sub_store} <- SwitchingStore.choose_store(store, ref),
           {:ok, first, rest_ref} = SwitchingStore.split_reference(ref) do
        new_sub_store = StorageCombinators.Storage.put(sub_store, rest_ref, value)
        new_path_store_map = Map.put(path_store_map, first, new_sub_store)
        new_store = SwitchingStore.switching_store(new_path_store_map)
        new_store
      else
        _ -> store
      end
    end

    def delete(%SwitchingStore{path_store_map: path_store_map} = store, ref) do
      with {:ok, sub_store} <- SwitchingStore.choose_store(store, ref),
           {:ok, first, rest_ref} = SwitchingStore.split_reference(ref) do
        new_sub_store = StorageCombinators.Storage.delete(sub_store, rest_ref)
        new_path_store_map = Map.put(path_store_map, first, new_sub_store)
        new_store = SwitchingStore.switching_store(new_path_store_map)
        new_store
      else
        _ -> store
      end
    end
  end
end
