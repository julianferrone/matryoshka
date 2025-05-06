defmodule Matryoshka.Impl.PersistentStore do
  alias Matryoshka.Impl.CachingStore
  alias Matryoshka.Impl.LogStore

  @doc """
  Creates a persistent store by first opening the log file using `LogStore.log_store/1`,
  then passing it to `CachingStore.caching_store/1` to apply caching functionality.

  This function takes a `log_filepath`, opens the log file through `LogStore.log_store/1`
  (which handles reading and writing the log file with an offset index),
  and then applies caching to it using `CachingStore.caching_store/1`.

  Returns the result of the `CachingStore.caching_store/1` function.
  """
  def persistent_store(log_filepath) do
    LogStore.log_store(log_filepath)
    |> CachingStore.caching_store()
  end
end
