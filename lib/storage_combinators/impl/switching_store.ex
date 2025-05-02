defmodule Matryoshka.Impl.SwitchingStore do
  alias Matryoshka.Impl.SwitchingStore
  alias Matryoshka.Reference
  alias Matryoshka.Storage
  import Matryoshka.Assert, only: [is_storage!: 1]

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

      iex> store = SwitchingStore.switching_store(%{
      ...>  "one" => MapStore.map_store(),
      ...>  "two" => MapStore.map_store()
      ...> })
      iex> store = Storage.put(store, "one/item", :item)
      iex> {_store, value} = Storage.fetch(store, "one/item")
      iex> value
      {:ok, :item}
      iex> {_store, value} = Storage.fetch(store, "two/item")
      iex> value
      {:error, {:no_ref, "item"}}
  """
  @spec switching_store(%{String.t() => impl_storage()}) :: SwitchingStore.t()
  def switching_store(path_store_map) when is_map(path_store_map) do
    Map.values(path_store_map)
    |> Enum.each(&is_storage!/1)

    %__MODULE__{
      path_store_map: path_store_map
    }
  end

  alias __MODULE__

  @spec update_substore(
          Matryoshka.Impl.SwitchingStore.t(),
          impl_storage(),
          Reference.impl_reference()
        ) ::
          Matryoshka.Impl.SwitchingStore.t()
  @doc """
  Updates a substore inside a SwitchingStore.
  """
  def update_substore(%SwitchingStore{path_store_map: path_store_map}, sub_store, sub_store_ref) do
    path_store_map
    |> Map.put(sub_store_ref, sub_store)
    |> SwitchingStore.switching_store()
  end

  @doc """
  Splits a reference into the first path segment and the rest of the path segments.

  ## Examples

      iex> SwitchingStore.split_reference("parent/child.txt")
      {:ok, "parent", "child.txt"}

      iex> SwitchingStore.split_reference("grandparent/parent/child.txt")
      {:ok, "grandparent", "parent/child.txt"}

      iex> SwitchingStore.split_reference("too_short.txt")
      {:error, {:ref_path_too_short, "too_short.txt"}}

      iex> SwitchingStore.split_reference("")
      {:error, {:ref_path_too_short, ""}}
  """
  @spec split_reference(any()) :: {:error, {:ref_path_too_short, any()}} | {:ok, any(), binary()}
  def split_reference(ref) do
    [path_head | path_tail] = Reference.path_segments(ref)

    case path_tail do
      [] -> {:error, {:ref_path_too_short, ref}}
      path -> {:ok, path_head, Enum.join(path, "/")}
    end
  end

  @doc """
  Locates a substore within a SwitchingStore from a Reference, then returns the
  substore, the first path segment of the Reference, and the remainder of the
  Reference.
  """
  def locate_substore(%SwitchingStore{path_store_map: path_store_map}, ref) do
    with {:split_ref, {:ok, path_first, path_rest}} <-
           {:split_ref, SwitchingStore.split_reference(ref)},
         {:fetch_substore, {:ok, sub_store}} <-
           {:fetch_substore, Map.fetch(path_store_map, path_first)} do
      {:ok, sub_store, path_first, path_rest}
    else
      {:split_ref, error} -> error
      {:fetch_substore, :error} -> {:error, :no_substore}
    end
  end

  defimpl Storage do
    def fetch(store, ref) do
      with {:locate, {:ok, sub_store, path_first, path_rest}} <-
             {:locate, SwitchingStore.locate_substore(store, ref)},
           {:fetch, {new_sub_store, {:ok, value}}} <-
             {:fetch, Storage.fetch(sub_store, path_rest)} do
        new_store = SwitchingStore.update_substore(store, new_sub_store, path_first)
        {new_store, {:ok, value}}
      else
        {:locate, error} -> {store, error}
        {:fetch, {store, error}} -> {store, error}
      end
    end

    def get(store, ref) do
      with {:ok, sub_store, path_first, path_rest} <-
             SwitchingStore.locate_substore(store, ref) do
        {new_sub_store, value} = Storage.get(sub_store, path_rest)
        new_store = SwitchingStore.update_substore(store, new_sub_store, path_first)
        {new_store, value}
      else
        _error -> {store, nil}
      end
    end

    def put(store, ref, value) do
      with {:ok, sub_store, path_first, path_rest} <-
             SwitchingStore.locate_substore(store, ref) do
        new_sub_store = Storage.put(sub_store, path_rest, value)
        SwitchingStore.update_substore(store, new_sub_store, path_first)
      else
        _ -> store
      end
    end

    def delete(store, ref) do
      with {:ok, sub_store, path_first, path_rest} <-
             SwitchingStore.locate_substore(store, ref) do
        new_sub_store = Storage.delete(sub_store, path_rest)
        SwitchingStore.update_substore(store, new_sub_store, path_first)
      else
        _ -> store
      end
    end
  end
end
