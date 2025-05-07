defmodule Matryoshka.Impl.LogStore.Deserialize do
  alias Matryoshka.Impl.LogStore.Encoding
  import :erlang, only: [binary_to_term: 1]

  # ____________________ Parsing Binaries ____________________

  @doc """
  Parses a binary representing a timestamp into a `DateTime` struct.

  The binary is expected to be a 64-bit big-endian unsigned integer,
  representing milliseconds since the Unix epoch.

  ## Parameters

    - `bin_timestamp`: Binary representation of the timestamp.

  ## Returns

    - `{:ok, datetime}` on success.
    - `{:error, reason}` if the timestamp is invalid.
  """
  def parse_timestamp(bin_timestamp) do
    timestamp_bitsize = Encoding.timestamp_bitsize()
    <<int_timestamp::big-unsigned-integer-size(timestamp_bitsize)>> = bin_timestamp
    DateTime.from_unix(int_timestamp, Encoding.time_unit())
  end

  @doc """
  Parses a binary representing the key size into an integer.

  The binary is expected to be a 16-bit big-endian unsigned integer.

  ## Parameters

    - `bin_key_size`: Binary representation of the key size.

  ## Returns

    - The key size as an integer.
  """
  def parse_key_size(bin_key_size) do
    key_bitsize = Encoding.key_bitsize()
    <<int_key_size::big-unsigned-integer-size(key_bitsize)>> = bin_key_size
    int_key_size
  end

  @doc """
  Parses a binary representing the value size into an integer.

  The binary is expected to be a 32-bit big-endian unsigned integer.

  ## Parameters

    - `bin_value_size`: Binary representation of the value size.

  ## Returns

    - The value size as an integer.
  """
  def parse_value_size(bin_value_size) do
    value_bitsize = Encoding.value_bitsize()
    <<int_value_size::big-unsigned-integer-size(value_bitsize)>> = bin_value_size
    int_value_size
  end

  # ___________________ Parsing Whole entrys __________________

  @doc """
  Parses a binary log entry and dispatches to the appropriate parser
  based on the encoded operation atom.

  log entrys begin with a timestamp (64 bits) followed by a serialized
  atom that indicates the operation type (`:w` for write, `:d` for delete).

  ## Parameters

    - `entry`: A binary log entry.

  ## Returns

    - `{:ok, {atom, key, value}}` for write operations.
    - `{:ok, {atom, key}}` for delete operations.
    - `{:err, {:no_entry_kind, atom}}` if the operation atom is unrecognized.
  """
  def parse_log_entry(entry) do
    timestamp_bitsize = Encoding.timestamp_bitsize()
    atom_bytesize = Encoding.atom_bytesize()

    <<_timestamp::big-unsigned-integer-size(timestamp_bitsize), rest::binary>> = entry
    <<binary_atom::binary-size(atom_bytesize), rest::binary>> = rest

    atom = binary_to_term(binary_atom)
    atom_write = Encoding.atom_write()
    atom_delete = Encoding.atom_delete()

    case atom do
      ^atom_write -> {:ok, parse_write_entry(rest)}
      ^atom_delete -> {:ok, parse_delete_entry(rest)}
      _ -> {:err, {:no_entry_kind, atom}}
    end
  end

  @doc """
  Parses a binary log entry representing a write operation.

  The format is:
  - 16-bit key size
  - 32-bit value size
  - Binary-encoded key
  - Binary-encoded value

  ## Parameters

    - `entry`: The binary data after the timestamp and atom.

  ## Returns

    - `{:w, key, value}`
  """
  def parse_write_entry(entry) do
    key_bitsize = Encoding.key_bitsize()
    value_bitsize = Encoding.value_bitsize()

    <<int_key_size::big-unsigned-integer-size(key_bitsize), rest::binary>> = entry
    <<int_value_size::big-unsigned-integer-size(value_bitsize), rest::binary>> = rest

    <<bin_key::binary-size(int_key_size), rest::binary>> = rest
    <<bin_value::binary-size(int_value_size), _rest::binary>> = rest

    key = binary_to_term(bin_key)
    value = binary_to_term(bin_value)
    {Encoding.atom_write(), key, value}
  end

  @doc """
  Parses a binary log entry representing a delete operation.

  The format is:
  - 16-bit key size
  - Binary-encoded key

  ## Parameters

    - `entry`: The binary data after the timestamp and atom.

  ## Returns

    - `{:ok, {:d, key}}`
  """
  def parse_delete_entry(entry) do
    key_bitsize = Encoding.key_bitsize()

    <<int_key_size::big-unsigned-integer-size(key_bitsize), rest::binary>> = entry

    <<bin_key::binary-size(int_key_size), _rest::binary>> = rest

    key = binary_to_term(bin_key)
    {Encoding.atom_delete(), key}
  end

  # __________________ Reading from Log File _________________

  # ----------------------- IO Helpers -----------------------

  def handle_io_result(:eof, _fun), do: :eof
  def handle_io_result({:error, reason}, _fun), do: {:error, reason}

  @doc """
  Handles the result of a binary IO read and optionally maps a function
  over the read bytes.

  ## Parameters

    - `:eof`: Signals end-of-file; returned directly.
    - `{:error, reason}`: An IO error; returned as `{:error, reason}`.
    - `bytes`: A binary; applies `fun` to it and returns `{:ok, result}`.

  ## Examples

      handle_io_result(:eof, &decode/1)
      # => :eof

      handle_io_result({:error, :closed}, &decode/1)
      # => {:error, :closed}

      handle_io_result(<<1, 2>>, &Enum.sum(:binary.bin_to_list(&1)))
      # => {:ok, 3}
  """
  def handle_io_result(bytes, fun), do: {:ok, fun.(bytes)}

  @doc """
  Reads a given number of bytes from a binary file descriptor and applies a
  function
  to the result if successful.

  Delegates handling of read results to `handle_io_result/2`.

  ## Parameters

    - `fd`: The IO device (e.g., a file descriptor).
    - `number_bytes`: Number of bytes to read.
    - `fun`: A function to apply to the read bytes if successful.

  ## Returns

    - `{:ok, result}` if read succeeds.
    - `:eof` or `{:error, reason}` otherwise.
  """
  def binread_then_map(fd, number_bytes, fun) do
    bytes = IO.binread(fd, number_bytes)
    handle_io_result(bytes, fun)
  end

  # ------------------ Reading Elixir Types ------------------

  @doc """
  Reads a big-endian unsigned integer of the given bit size from the file
  descriptor.

  The integer is read as raw bytes and then interpreted using binary pattern
  matching.

  ## Parameters

    - `fd`: An IO device (e.g., file descriptor).
    - `int_size`: The number of bits in the integer to read.

  ## Returns

    - `{:ok, integer}` on success.
    - `:eof` or `{:error, reason}` on failure.
  """
  def read_big_unsigned_integer(fd, int_size) do
    number_bytes = Encoding.bits_to_bytes(int_size)

    binread_then_map(fd, number_bytes, fn bytes ->
      <<int::big-unsigned-integer-size(int_size)>> = bytes
      int
    end)
  end

  @doc """
  Reads a fixed-size atom from the file descriptor and deserializes it using
  `:erlang.binary_to_term/1`.

  The atom must have been previously serialized to a fixed number of bytes.

  ## Parameters

    - `fd`: An IO device.

  ## Returns

    - `{:ok, atom}` on success.
    - `:eof` or `{:error, reason}` on failure.
  """
  def read_atom(fd) do
    atom_bytesize = Encoding.atom_bytesize()

    binread_then_map(
      fd,
      atom_bytesize,
      fn bytes ->
        <<binary_atom::binary-size(atom_bytesize)>> = bytes
        atom = binary_to_term(binary_atom)
        atom
      end
    )
  end

  @doc """
  Reads a timestamp from the file descriptor and converts it to a `DateTime`
  struct.

  The timestamp is stored as a big-endian unsigned integer and interpreted
  using the configured time unit (e.g., milliseconds).

  ## Parameters

    - `fd`: An IO device.

  ## Returns

    - `{:ok, %DateTime{}}` on success.
    - `:eof` or `{:error, reason}` on failure or invalid timestamp.
  """
  def read_timestamp(fd) do
    timestamp_bitsize = Encoding.timestamp_bitsize()

    with {:ok, timestamp_int} <- read_big_unsigned_integer(fd, timestamp_bitsize) do
      DateTime.from_unix(timestamp_int, Encoding.time_unit())
    else
      other -> other
    end
  end

  # -------------------- Reading log entrys -------------------

  # .................... Read Entire entry ....................

  @doc """
  Reads a full log entry from the given file descriptor and parses it based on
  the entry kind.

  The entry is expected to start with a timestamp and an atom tag indicating
  whether it's a write (`:w`) or delete (`:d`) operation, followed by the
  appropriate data.

  ## Parameters

    - `fd`: An IO device.

  ## Returns

    - `{:ok, {kind, key, value}}` for write operations.
    - `{:ok, {kind, key}}` for delete operations.
    - `{:error, {:no_entry_kind, atom}}` for unrecognized entry types.
    - `:eof` or `{:error, reason}` on read failure.
  """
  def read_log_entry(fd) do
    _timestamp = read_timestamp(fd)
    entry_kind = read_atom(fd)
    atom_write = Encoding.atom_write()
    atom_delete = Encoding.atom_delete()

    case entry_kind do
      {:ok, ^atom_write} -> read_write_entry(fd)
      {:ok, ^atom_delete} -> read_delete_entry(fd)
      {:ok, atom} -> {:error, {:no_entry_kind, atom}}
      other -> other
    end
  end

  @doc """
  Reads a write log entry from the file descriptor.

  This includes reading the key and value sizes, followed by the serialized key
  and value terms.

  ## Parameters

    - `fd`: An IO device.

  ## Returns

    - `{:ok, {:w, key, value}}` on success.
    - `:eof` or `{:error, reason}` on failure.
  """
  def read_write_entry(fd) do
    with {:ok, key_size} <- read_big_unsigned_integer(fd, Encoding.key_bitsize()),
         {:ok, value_size} = read_big_unsigned_integer(fd, Encoding.value_bitsize()),
         {:ok, key} <-
           binread_then_map(fd, key_size, &binary_to_term/1),
         {:ok, value} <-
           binread_then_map(fd, value_size, &binary_to_term/1) do
      {:ok, {Encoding.atom_write(), key, value}}
    else
      error -> error
    end
  end

  @doc """
  Reads a delete log entry from the file descriptor.

  This includes reading the key size and the serialized key term.

  ## Parameters

    - `fd`: An IO device.

  ## Returns

    - `{:ok, {:d, key}}` on success.
    - `:eof` or `{:error, reason}` on failure.
  """
  def read_delete_entry(fd) do
    with {:ok, key_size} <- read_big_unsigned_integer(fd, Encoding.key_bitsize()),
         {:ok, key} <-
           binread_then_map(fd, key_size, &binary_to_term/1) do
      {:ok, {Encoding.atom_delete(), key}}
    else
      error -> error
    end
  end

  # ............... Load Offsets and Value Size ..............

  @doc """
  Loads key-to-offset mappings from a log file.

  Starts scanning from the beginning of the file, reading each log entry and
  calculating the offset to the value (for `:w`) or marking it deleted
  (for `:d`).

  ## Parameters

    - `fd`: An IO device opened for reading.

  ## Returns

    - A map of keys to `{value_offset, value_size}` tuples.
  """
  def load_offsets(fd) do
    load_offsets(fd, Map.new(), 0)
  end

  def load_offsets(fd, offsets, current_offset) do
    :file.position(fd, current_offset)

    with {:ok, _timestamp} <- read_timestamp(fd),
         {:ok, entry_kind} <- read_atom(fd),
         {:ok, {key, key_size, value_size}} <- load_offsets_entry(fd, entry_kind) do
      relative_offset_to_value =
        case value_size do
          nil ->
            Encoding.delete_entry_size(key_size)

          _nonzero ->
            Encoding.write_entry_pre_value_size(key_size)
        end

      relative_offset_to_end =
        case value_size do
          nil -> Encoding.delete_entry_size(key_size)
          value_size -> Encoding.write_entry_size(key_size, value_size)
        end

      value_offset =
        current_offset + relative_offset_to_value

      offsets = Map.put(offsets, key, {value_offset, value_size})

      absolute_offset =
        current_offset + relative_offset_to_end

      load_offsets(fd, offsets, absolute_offset)
    else
      :eof -> offsets
    end
  end

  def load_offsets_entry(fd, entry_kind) do
    atom_write = Encoding.atom_write()
    atom_delete = Encoding.atom_delete()

    case entry_kind do
      ^atom_write -> load_offsets_write_entry(fd)
      ^atom_delete -> load_offsets_delete_entry(fd)
      atom when is_atom(atom) -> {:error, {:no_lin_kind, atom}}
      other -> other
    end
  end

  def load_offsets_write_entry(fd) do
    with {:ok, key_size} <- read_big_unsigned_integer(fd, Encoding.key_bitsize()),
         {:ok, value_size} <- read_big_unsigned_integer(fd, Encoding.value_bitsize()) do
      binread_then_map(fd, key_size, fn key_bin ->
        key = binary_to_term(key_bin)
        {key, key_size, value_size}
      end)
    end
  end

  def load_offsets_delete_entry(fd) do
    key_size = read_big_unsigned_integer(fd, Encoding.key_bitsize())

    binread_then_map(fd, key_size, fn key_bin ->
      key = binary_to_term(key_bin)
      {key, key_size, nil}
    end)
  end

  # ------------------- Reading Whole File -------------------

  @doc """
  Builds an index of key-to-value offsets from a log file.

  Opens the log file at the given `log_filepath`, reads each entry,
  and returns a map from keys to `{value_offset, value_size}` tuples.

  This index can be used for efficient key lookup without scanning the entire file.

  ## Parameters

    - `log_filepath`: Path to the log file.

  ## Returns

    - `{:ok, index}` on success.
    - `{:error, reason}` if the file cannot be opened.
  """
  def get_index(log_filepath) do
    with {:ok, file} <- File.open(log_filepath, [:binary, :read]) do
      load_offsets(file)
    end
  end

  # ----------------- Read Value at Position -----------------

  @doc """
  Reads and deserializes the value from the given file descriptor at the
  specified offset and size.

  This is used to retrieve the value associated with a key from the log file
  using the offset and size from the index.

  ## Parameters

    - `fd`: The file descriptor for the log file (must be opened in binary mode).
    - `offset`: The byte offset in the file where the value starts.
    - `size`: The size in bytes of the serialized value (must not be `nil`).

  ## Returns

    - `{:ok, term}` if the value is successfully read and deserialized.
    - `{:error, reason}` if reading fails.
  """
  def get_value(fd, offset, size) when not is_nil(size) do
    with {:ok, bin} <- :file.pread(fd, offset, size) do
      {:ok, binary_to_term(bin)}
    else
      other -> other
    end
  end
end
