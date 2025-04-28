# StorageCombinators

StorageCombinators is an implementation in Elixir of the ideas about composable storage in (Weiher & Hirschfeld, 2019).

Any module that implements the Storage protocol (get, fetch, put, delete) is a **store**. Stores don't need to actually store data, but can compute it, as long as it implements the protocol.

Some stores compute their results by referring to other stores. These are known as **storage combinators**.

## Using StorageCombinators

Stores and store combinators are composed together using the functions found 
in the module **StorageCombinators**. After starting the server, the store can
be interacted with using the functions `get`, `put`, `fetch`, and `delete`.

- `get(path)` returns the `value` at the given `path` if it exists, or `nil` if
  not.
- `fetch(path)` returns `{:ok, value}` if the value exists at the given `path`,
  or `{:error, reason}` if not
- `put(path, value)` puts the `value` into the store at the given `path`
- `delete(path)` deletes the `value` in the store at the given `path`

```elixir
# Composing stores together
{:ok, client} = 
  map_store()
  |> logging_store()
  # Initializing storage server
  |> StorageCombinators.start_link()

put("one", :item)
get("one")
#=> :item
```

## Implementation of Storage Protocol

The business logic of different stores and store combinators is found under /lib/storage_combinators/impl/. 

| Store Struct | Function | Explanation | Store Combinator? | Wrapped stores |
| --- | --- | --- | --- | --- |
| CachingStore | `caching_store/1`, `caching_store/2` | Directs storage calls to a fast cache store (on all calls) and a slow main store (always on put / delete, only if not available in fast cache store on get / fetch). | ✅ | Takes 2 underlying stores |
| LoggingStore | `logging_store/1` | Logs all storage calls | ✅ | Takes 1 underlying store  |
| MapStore | `map_store/0`, `map_store/1` | Provides a Map-backed store | ❌ | N/A |
| MappingStore | `mapping_store/2` | Applies functions to the reference path, items on retrieval, and items on storage. | ✅ | Takes 1 underlying store | 
| PassThrough | `pass_through/1` | Directs all calls to the inner store and does nothing | ✅ | Takes 1 underlying store |
| SwitchingStore | `switching_store/1` | Directs all storage calls | ✅ | Takes a Map of strings to underlying stores |

Of these, PassThrough is useless, and is provided only to compare with the PassThrough store in (Weiher & Hirschfeld, 2019).

## To-Do

- [ ] Add FileStore as disk based storage.
- [ ] Add JsonStore and XmlStore as specialisations of MappingStore
- [ ] Add patch functionality
  - This will probably only be allowed for certain values like JSON or XML, using RFC 6902 JSON Patch and RFC 5261 XML Patch Operations 

## References

Weiher, M., & Hirschfeld, R. (2019). **Storage combinators**. *Proceedings of the 2019 ACM SIGPLAN International Symposium on New Ideas, New Paradigms, and Reflections on Programming and Software*, 111–127. [![DOI:10.1145/3359591.3359729](https://zenodo.org/badge/DOI/10.1145/3359591.3359729.svg)](https://doi.org/10.1145/3359591.3359729)
