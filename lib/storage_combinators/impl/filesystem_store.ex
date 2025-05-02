defmodule StorageCombinators.Impl.FilesystemStore do
  @moduledoc """
  A file-backed storage implementation for the `StorageCombinators.Storage`
  protocol.

  This store persists values as files on disk, using the reference path
  segments to determine the file location relative to a given root directory.
  Each reference is mapped to a single file, and the file contents are treated
  as raw binary or text.

  ## Usage

  You can create a new `FilesystemStore` by calling:

      store = StorageCombinators.Impl.FilesystemStore.filesystem_store(
        "/tmp/storage"
      )

  Operations like `get`, `put`, `fetch`, and `delete` will resolve paths
  relative to this root directory, using the reference's `path_segments()`.

  For example, if the reference has segments `["users", "alice", "bio"]`, and
  the store was created with the root `/tmp/storage`, then the value will be
  stored in:

      /tmp/storage/users/alice/bio

  The FilesystemStore only ever returns String values, and can only be used
  to insert String values, as it performs no mapping of objects to Strings
  before storing the data. If you want to insert arbitrary data, it needs
  to be composed as the inner store of a MappingStore which takes care of
  serialization/deserialization.

  ## Behavior

  Implements the `StorageCombinators.Storage` protocol:

    * `fetch/2` reads the file and returns `{:ok, value}` or
      `{:error, {:no_ref, ref}}`
    * `get/2` returns the value or `nil` if missing
    * `put/3` creates or overwrites the file at the resolved path
    * `delete/2` removes the file if it exists

  Intermediate directories are automatically created on `put/3`.

  ## Example

      store = StorageCombinators.Impl.FilesystemStore.filesystem_store("/tmp/example")
      ref = Reference.from_path("posts/hello")
      store = Storage.put(store, ref, "Hello, filesystem!")
      {_store, value} = Storage.fetch(store, ref)
      value
      {:ok, "Hello, filesystem!"}

  """
  alias StorageCombinators.Reference
  alias StorageCombinators.Storage

  @enforce_keys [:root_dir]
  defstruct @enforce_keys

  @typedoc """
  A struct representing a filesystem-backed storage root.

  All operations like `get`, `put`, and `delete` are performed relative to the
  `root_dir`, which is the base directory for this store's contents on disk.
  """
  @type t :: %__MODULE__{
          root_dir: Path.t()
        }

  @doc """
  Creates a new `%FilesystemStore{}` rooted at the given directory.

  All reference paths used by this store will be resolved relative to this
  root directory. The path should be a valid absolute or relative path on
  the filesystem.

  ## Examples

      store = FilesystemStore.filesystem_store("/tmp/storage")

  """
  @spec filesystem_store(Path.t()) :: t()
  def filesystem_store(root_dir) do
    %__MODULE__{root_dir: root_dir}
  end

  @doc """
  Returns the absolute file path for the given reference, relative to the
  store's root directory.

  The reference must implement `path_segments/0`, returning a list of strings
  which are joined with the store's root to form a file system path.

  This is a low-level utility function, primarily used by the storage protocol
  methods like `fetch`, `get`, `put`, and `delete`.

  ## Examples

      store = FilesystemStore.filesystem_store("/tmp/storage")
      ref = Reference.from_path("users/alice/bio")
      FilesystemStore.absolute_path(store, ref)
      "/tmp/storage/users/alice/bio"

  """
  @spec absolute_path(t(), Reference.t()) :: Path.t()
  def absolute_path(store, ref) do
    path_segments = [store.root_dir | Reference.path_segments(ref)]
    Path.join(path_segments)
  end

  alias __MODULE__

  defimpl Storage do
    def fetch(store, ref) do
      path = FilesystemStore.absolute_path(store, ref)

      with {:ok, value} <- File.read(path) do
        {store, {:ok, value}}
      else
        {:error, _reason} -> {store, {:error, {:no_ref, ref}}}
      end
    end

    def get(store, ref) do
      path = FilesystemStore.absolute_path(store, ref)

      with {:ok, value} <- File.read(path) do
        {store, value}
      else
        {:error, _reason} -> {store, nil}
      end
    end

    def put(store, ref, value) when is_binary(value) do
      path = FilesystemStore.absolute_path(store, ref)
      parent_dir = Path.dirname(path)
      File.mkdir_p(parent_dir)
      File.write(path, value)

      store
    end

    def delete(store, ref) do
      path = FilesystemStore.absolute_path(store, ref)
      _result = File.rm(path)
      store
    end
  end
end
