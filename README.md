# StorageCombinators

StorageCombinators is an implementation of the ideas about composable storage components in *Storage combinators*[^sc] in Elixir.

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

| Store name | Explanation | Store Combinator? |
| --- | --- |
| CachingStore | Directs storage calls to a fast cache store (on all calls) and a slow main store (always on put / delete, only if not available in fast cache store on get / fetch). | ✅ -- takes 2 underlying stores |
| LoggingStore | Logs all storage calls | ✅ -- takes 1 underlying store  |
| MapStore | Provides a map-backed store | ❌ |
| MappingStore | Applies functions to the reference path, items on retrieval, and items on storage. | ✅ -- takes 1 underlying store | 
| PassThrough | Directs all calls to the inner store and does nothing | ✅ |
| SwitchingStore | Directs all storage calls | ✅ -- takes a map of strings to underlying stores |

Of these, PassThrough is useless, and is provided only to compare with the PassThrough store in *Storage combinators*[^sc].

## To-Do

- [ ] Add FileStore as disk based storage.
- [ ] Add Json and Xml stores as specialisations of MappingStore
- [ ] Add patch functionality
  - This will probably only be allowed for certain values like JSON or XML, using RFC 6902 JSON Patch and RFC 5261 XML Patch Operations 

## References

[^sc]: *Marcel Weiher and Robert Hirschfeld.* (2019). **Storage combinators**. In Proceedings of the 2019 ACM SIGPLAN International Symposium on New Ideas, New Paradigms, and Reflections on Programming and Software (Onward! 2019). Association for Computing Machinery, New York, NY, USA, 111–127. [![DOI:10.1145/3359591.3359729]](https://zenodo.org/badge/DOI/10.1145/3359591.3359729.svg)](https://doi.org/10.1145/3359591.3359729)