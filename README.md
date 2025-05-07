# Matryoshka

Matryoshka is an implementation in Elixir of the ideas about composable storage in (Weiher & Hirschfeld, 2019).

Any module that implements the Storage protocol (get, fetch, put, delete) is a **store**. Stores don't need to actually store data, but can compute it, as long as it implements the protocol.

Some stores produce their results by adding behaviour on top of inner sub-stores. These are known as **storage combinators**.

## Why "Matryoshka"?

Because the stores nest inside each other like [Matryoshka dolls](https://en.wikipedia.org/wiki/Matryoshka_doll).

## Using Matryoshka

Stores and store combinators are composed together using the functions found 
in the module **Matryoshka**. After starting the server, the store can
be interacted with using the functions `get`, `put`, `fetch`, and `delete`.

- `get(server, path)` returns the `value` at the given `path` if it exists, or `nil` if
  not.
- `fetch(server, path)` returns `{:ok, value}` if the value exists at the given `path`,
  or `{:error, reason}` if not
- `put(server, path, value)` puts the `value` into the store at the given `path`
- `delete(server, path)` deletes the `value` in the store at the given `path`

```elixir
alias Matryoshka
# Composing stores together
{:ok, store} = 
  Matryoshka.map_store()
  |> Matryoshka.logging_store()
  # Initializing storage server
  |> Matryoshka.start_link()

Matryoshka.put(store, "key", :value)
#=> :ok
#=> 10:20:30.000 [info] [request: :put, ref: "key", value: :value]

Matryoshka.get(store, "key")
#=> 10:20:35.000 [info] [request: :get, ref: "key", value: :value]
#=> :value
```

## Implementation of Storage Protocol

The business logic of different stores and store combinators is found under /lib/storage_combinators/impl/. 

| Store Struct | Function | Explanation | Store Combinator? | Wrapped stores |
| --- | --- | --- | --- | --- |
| CachingStore | `caching_store/1`, `caching_store/2` | Directs storage calls to a fast cache store (on all calls) and a slow main store (always on put / delete, only if not available in fast cache store on get / fetch). | ✅ | Takes 2 underlying stores |
| FilesystemStore | `filesystem_store/1` | Persists values as files on disk, using the reference path as a relative path to the given root directory. Each reference is mapped to a different file. | ❌ | N/A |
| LoggingStore | `logging_store/1` | Logs all storage calls | ✅ | Takes 1 underlying store  |
| LogStore | `log_store/1` | Persists puts and deletes as binary entries in an append-only log, and looks up gets and fetches using an index. | ❌ | N/A |
| MapStore | `map_store/0`, `map_store/1` | Provides a Map-backed store | ❌ | N/A |
| MappingStore | `mapping_store/2` | Applies functions to the reference path, items on retrieval, and items on storage. | ✅ | Takes 1 underlying store | 
| PassThrough | `pass_through/1` | Directs all calls to the inner store and does nothing | ✅ | Takes 1 underlying store |
| PersistentStore | `persistent_store/1` | Persists puts and deletes to an append-only log, and caches storage calls for fast data access. | ❌ | N/A |
| SwitchingStore | `switching_store/1` | Directs all storage calls to inner stores depending on the first path segment of the `path` | ✅ | Takes a Map of strings to underlying stores |

Of these, PassThrough is useless, and is provided only to compare with the PassThrough store in (Weiher & Hirschfeld, 2019).

## To-Do

- [x] Add FilesystemStore as file-system based storage
- [ ] Add JsonStore and XmlStore as specialisations of MappingStore
- [ ] Add patch functionality
  - This will probably only be allowed for certain values like JSON or XML, using RFC 6902 JSON Patch and RFC 5261 XML Patch Operations 
- [x] Add persistent key-value storage in LogStore
  - using an append-only log approach
- [ ] Add a store that stores values in either a persistent KV store or as files depending on the size of the value

## References

Weiher, M., & Hirschfeld, R. (2019). **Storage combinators**. *Proceedings of the 2019 ACM SIGPLAN International Symposium on New Ideas, New Paradigms, and Reflections on Programming and Software*, 111–127. [![DOI:10.1145/3359591.3359729](https://zenodo.org/badge/DOI/10.1145/3359591.3359729.svg)](https://doi.org/10.1145/3359591.3359729)
