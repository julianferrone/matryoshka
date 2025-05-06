defmodule Matryoshka do
  # Implementation logic
  alias Matryoshka.Impl.CachingStore
  alias Matryoshka.Impl.FilesystemStore
  alias Matryoshka.Impl.LoggingStore
  alias Matryoshka.Impl.LogStore
  alias Matryoshka.Impl.MapStore
  alias Matryoshka.Impl.MappingStore
  alias Matryoshka.Impl.PassThrough
  alias Matryoshka.Impl.SwitchingStore

  # Client to interact with store
  alias Matryoshka.Client

  @doc """
  Starts the storage server from a provided store.

  ## Examples

      {:ok, pid} = map_store() |> start_link()
  """
  def start_link(store), do: Client.start_link(store)

  @doc """
  Gets a value from the storage server from the provided `ref`.

  ## Examples

      iex> put("item", :item)
      iex> get("item")
      :item
      iex> get("not_existing")
      nil
  """
  def get(ref), do: Client.get(ref)

  @doc """
  Fetches a value from the storage server from the provided `ref`.

  ## Examples

      iex> put("item", :item)
      iex> fetch("item")
      {:ok, :item}
      iex> fetch("not_existing")
      {:error, {:no_ref, "not_existing"}}
  """
  def fetch(ref), do: Client.fetch(ref)

  @doc """
  Puts a value into the storage server at the provided `ref`.

  ## Examples

      iex> put("item", :item)
      iex> fetch("item")
      {:ok, :item}
  """
  defdelegate put(ref, value), to: Client

  @doc """
  Fetches a value from the storage server from the provided `ref`.

  ## Examples

      iex> put("item", :item)
      iex> fetch("item")
      {:ok, :item}
      iex> delete("item")
      iex> fetch("item")
      {:error, {:no_ref, "item"}}
  """
  defdelegate delete(ref), to: Client

  @doc """
  Creates a `CachingStore` backed by a `MapStore` as the fast cache.

  This is a convenience function that automatically wraps the given `main_store`
  with a new in-memory `MapStore` for fast access.

  ## Parameters

    * `main_store` - The primary storage module or instance that acts as the
      source of truth. Must implement the `Matryoshka.Storage` protocol.

  ## Returns

  A `CachingStore` struct wrapping the `main_store` and a new `MapStore` as
  the fast cache.
  """
  defdelegate caching_store(main_store), to: CachingStore

  @doc """
  Creates a `CachingStore` from a `main_store` (source of truth) and a
  `fast_store` (cache).

  The `CachingStore` first attempts to read from `fast_store` for faster
  access, falling back to `main_store` if necessary. On successful reads
  from `main_store`, the value is populated into the `fast_store` to speed
  up future access.

  ## Parameters

    * `main_store` - The primary store holding the authoritative data.
      Must implement the `Matryoshka.Storage` protocol.
    * `fast_store` - A secondary, faster-access store used for caching
      lookups. Must also implement the `Matryoshka.Storage`
      protocol.

  ## Returns

  A `CachingStore` struct that wraps both the `main_store` and the
  `fast_store`.

  ## Raises

  Raises an error if either `main_store` or `fast_store` does not implement
  the required Storage protocol.
  """
  defdelegate caching_store(main_store, fast_store), to: CachingStore

  @doc """
  Creates a new `%FilesystemStore{}` rooted at the given directory.

  All reference paths used by this store will be resolved relative to this
  root directory. The path should be a valid absolute or relative path on
  the filesystem.

  ## Examples

      store = filesystem_store("/tmp/storage")

  """
  defdelegate filesystem_store(root_dir), to: FilesystemStore

  @doc """
  Wraps a store with logging functionality.

  The `LoggingStore` logs all `get`, `put`, `patch`, and `delete` operations
  performed on the inner store. This is useful for debugging or auditing storage behavior.

  ## Parameters

    * `storage` - The underlying storage to wrap. Must implement the
      `Matryoshka.Storage` protocol.

  ## Returns

  A `%LoggingStore{}` struct that wraps the given `storage`.

  ## Raises

  Raises an error if `storage` does not implement the required
  `Matryoshka.Storage` protocol.
  """
  defdelegate logging_store(store), to: LoggingStore

  @doc """
  Opens a log file, either loading its offset index or creating a new one if
  the file doesn't exist.

  The function attempts to open the log file at the given `log_filepath`.

  If the file exists, it loads the key-value offsets and opens the file for
  both reading and writing. If the file doesn't exist, it creates a new index
  and opens the file for both reading and writing.

  Returns a `%__MODULE__{}` struct containing the following:
    - `reader`: The file descriptor for reading from the log file.
    - `writer`: The file descriptor for writing to the log file.
    - `index`: A map representing the offset index of the log file.

  If the log file doesn't exist, the index is initialized as an empty map.
  """
  defdelegate log_store(log_filepath), to: LogStore

  @doc """
  Creates a new `MapStore` backed by an empty `Map`.

  Returns a `%MapStore{}` with an empty map.
  """
  defdelegate map_store(), to: MapStore

  @doc """
  Creates a new `MapStore` from an existing map.

  ## Parameters

    * `map` - An existing `%{}` map to use as the backing store.

  Returns a `%MapStore{}` wrapping the given map.
  """
  defdelegate map_store(map), to: MapStore

  @doc """
  Wraps an inner store with a mapping layer.

  The `mapping_store/2` function allows you to map values when reading from
  or writing to the `inner` store. It accepts an `inner` store and an optional
  list of options.

  ## Parameters

  * `inner` - The underlying store module or instance to wrap. Must implement
    the `Matryoshka.Storage` protocol.
  * `opts` - (keyword list) Optional settings:

    * `:map_to_store` - (function) A function `(value -> stored_value)` that
      maps values *before* storing them. Defaults to `Function.identity/1`.
    * `:map_retrieved` - (function) A function `(stored_value -> value)` that
      maps values when retrieved (get/fetch) from the store. Defaults to
      `Function.identity/1`.
    * `:map_ref` - (function). A function that maps references
      `(ref -> mapped_ref)` before using them to locate values. Defaults to
      `Function.identity/1`.

  If the mapping function aren't provided, values and references are passed
  through unchanged.
  """
  defdelegate mapping_store(store, opts), to: MappingStore

  @doc """
  Wraps a storage with a `PassThrough` combinator.

  The `PassThrough` combinator simply delegates all storage operations to the
  inner storage.

  ## Parameters

    * `storage` — A struct implementing the `Matryoshka.Storage`
    protocol.

  ## Returns

  A `%PassThrough{}` wrapping the given storage.
  """
  defdelegate pass_through(store), to: PassThrough

  @doc """
  Creates a `SwitchingStore` that routes `fetch`, `get`, `put`, and `delete`
  requests to different sub-stores based on the first segment of the path.

  Each sub-store is mapped by a string key. The first segment of the given
  reference is used to select the appropriate sub-store to handle the
  operation.

  ## Parameters

  * `path_store_map` — A map where keys are `String.t()` representing the
    first path segment, and values are storages implementing the
    `Matryoshka.Storage` protocol.
  """
  defdelegate switching_store(path_store_map), to: SwitchingStore
end
