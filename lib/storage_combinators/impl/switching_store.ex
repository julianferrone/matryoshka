defmodule StorageCombinators.Impl.SwitchingStore do
  alias StorageCombinators.Impl.SwitchingStore
  alias StorageCombinators.Reference
  alias StorageCombinators.Storage
  import StorageCombinators.StorageCombinators, only: [is_storage!: 1]

  @enforce_keys [:path_store_map]
  defstruct @enforce_keys

  @typedoc """
  A struct that implements the Storage protocol.
  """
  @type impl_storage :: any()

  @type t :: %__MODULE__{
          path_store_map: %{String.t() => impl_storage()}
        }

  @doc """
  Creates a SwitchingStore that routes fetch/get/put/delete requests to different
  sub-stores depending on the first segment of the path.

  ## Examples

      iex> store = SwitchingStore.switching_store(%{"one" => MapStore.map_store(), "two" => MapStore.map_store()})
      iex> store = Storage.put(store, "one/item", :item)
      iex> {_store, value} = Storage.fetch(store, "one/item")
      iex> value
      {:ok, :item}
      iex> {_store, value} = Storage.fetch(store, "two/item")
      iex> value
      {:error, {:no_ref, "item"}}
  """
  @spec switching_store(%{String.t() => impl_storage()} | impl_storage()) :: SwitchingStore.t()
  def switching_store(path_store_map) when is_map(path_store_map) do
    Map.values(path_store_map)
    |> Enum.each(&is_storage!/1)

    %__MODULE__{
      path_store_map: path_store_map
    }
  end

  alias __MODULE__

  @spec split_reference(any()) :: {:error, {:ref_path_too_short, any()}} | {:ok, any(), binary()}
  def split_reference(ref) do
    [path_head | path_tail] = Reference.path_segments(ref)

    case path_tail do
      [] -> {:error, {:ref_path_too_short, ref}}
      path -> {:ok, path_head, Enum.join(path, "/")}
    end
  end

  def locate_substore(%SwitchingStore{path_store_map: path_store_map}, ref) do
    with {:split_ref, {:ok, path_first, path_rest}} <-
           {:split_ref, SwitchingStore.split_reference(ref)},
         {:fetch_substore, {:ok, sub_store}} <-
           {:fetch_substore, Map.fetch(path_store_map, path_first)} do
      {:ok, sub_store, path_first, path_rest}
    else
      {:split_ref, {:error, error}} -> {:error, error}
      {:fetch_substore, :error} -> {:error, :no_substore}
    end
  end

  defimpl Storage do
    def fetch(%SwitchingStore{path_store_map: path_store_map} = store, ref) do
      with {:locate, {:ok, sub_store, path_first, path_rest}} <-
             {:locate, SwitchingStore.locate_substore(store, ref)},
           {:update_substore, {new_sub_store, {:ok, value}}} <-
             {:update_substore, Storage.fetch(sub_store, path_rest)} do
        new_path_store_map = Map.put(path_store_map, path_first, new_sub_store)
        new_store = SwitchingStore.switching_store(new_path_store_map)
        {new_store, {:ok, value}}
      else
        {:locate, error} -> {store, error}
        {:update_substore, {store, error}} -> {store, error}
      end
    end

    def get(%SwitchingStore{path_store_map: path_store_map} = store, ref) do
      with {:locate, {:ok, sub_store, path_first, path_rest}} <-
             {:locate, SwitchingStore.locate_substore(store, ref)} do
        {new_sub_store, value} = Storage.get(sub_store, path_rest)
        new_path_store_map = Map.put(path_store_map, path_first, new_sub_store)
        new_store = SwitchingStore.switching_store(new_path_store_map)
        {new_store, value}
      else
        {:locate, error} -> {store, nil}
      end
    end

    def put(%SwitchingStore{path_store_map: path_store_map} = store, ref, value) do
      with {:locate, {:ok, sub_store, path_first, path_rest}} <-
             {:locate, SwitchingStore.locate_substore(store, ref)} do
        new_sub_store = Storage.put(sub_store, path_rest, value)
        new_path_store_map = Map.put(path_store_map, path_first, new_sub_store)
        new_store = SwitchingStore.switching_store(new_path_store_map)
        new_store
      else
        _ -> store
      end
    end

    def delete(%SwitchingStore{path_store_map: path_store_map} = store, ref) do
      with {:locate, {:ok, sub_store, path_first, path_rest}} <-
             {:locate, SwitchingStore.locate_substore(store, ref)} do
        new_sub_store = Storage.delete(sub_store, path_rest)
        new_path_store_map = Map.put(path_store_map, path_first, new_sub_store)
        new_store = SwitchingStore.switching_store(new_path_store_map)
        new_store
      else
        _ -> store
      end
    end
  end
end
