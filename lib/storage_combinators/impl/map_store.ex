defmodule Matryoshka.Impl.MapStore do
  @enforce_keys [:map]
  defstruct [:map]

  @type t :: %__MODULE__{
          map: map()
        }

  @doc """
  Creates a key-value store that is backed by a Elixir Map.

  ## Examples
      iex> MapStore.map_store()
      %Matryoshka.Impl.MapStore{map: %{}}

      iex> store = MapStore.map_store()
      iex> store = Storage.put(store, "one", :one)
      iex> {_store, value} = Storage.fetch(store, "one")
      iex> value
      {:ok, :one}
  """
  def map_store(), do: map_store(Map.new())
  def map_store(map), do: %__MODULE__{map: map}

  alias __MODULE__

  defimpl Matryoshka.Storage do
    def fetch(%MapStore{map: map} = store, ref) do
      value =
        case Map.fetch(map, ref) do
          {:ok, value} -> {:ok, value}
          :error -> {:error, {:no_ref, ref}}
        end

      {store, value}
    end

    def get(%MapStore{map: map} = store, ref) do
      {store, Map.get(map, ref)}
    end

    def put(%MapStore{map: map}, ref, value) do
      inner = Map.put(map, ref, value)
      MapStore.map_store(inner)
    end

    def delete(%MapStore{map: map}, ref) do
      inner = Map.delete(map, ref)
      MapStore.map_store(inner)
    end
  end
end
