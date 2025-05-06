defmodule Matryoshka.Client do
  @moduledoc """
  """
  alias Matryoshka.Reference
  @server Matryoshka.Server

  @type value :: any()

  @doc """
  Starts the storage server

  ## Examples

      iex> alias Matryoshka.Impl.MapStore
      iex> {:ok, client} = MapStore.map_store() |> start_link()
      iex> client.put("item", :item)
      iex> client.get("item")
      :item
  """
  def start_link(store, options \\ []) do
    @server.start_link(store, options)
  end

  @doc """
  Gets a value

  ## Examples

      iex> {:ok, client} = Matryoshka.Impl.MapStore.map_store() |> Matryoshka.Client.start_link()
      iex> client.put("item", :item)
      iex> client.get("item")
      :item
      iex> client.fetch("item")

  """
  @spec get(GenServer.server(), Reference.t()) :: value() | nil
  def get(pid, ref) do
    GenServer.call(pid, {:get, ref})
  end

  @spec fetch(GenServer.server(), Reference.t()) :: {:ok, value()} | :error
  def fetch(pid, ref) do
    GenServer.call(pid, {:fetch, ref})
  end

  @spec put(GenServer.server(), Reference.t(), term()) :: :ok
  def put(pid, ref, value) do
    GenServer.cast(pid, {:put, ref, value})
  end

  @spec delete(GenServer.server(), Reference.t()) :: :ok
  def delete(pid, ref) do
    GenServer.cast(pid, {:delete, ref})
  end
end
