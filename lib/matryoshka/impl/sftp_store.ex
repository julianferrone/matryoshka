defmodule Matryoshka.Impl.SftpStore do
  alias Matryoshka.Reference
  @enforce_keys [:pid, :connection]
  defstruct [:pid, :connection]
  alias __MODULE__

  @type t :: %SftpStore{
          pid: pid(),
          connection: :ssh.connection_ref()
        }

  @doc """
  Creates a store backed by an SSH FTP (SFTP) client.

  ## Parameters

    * `host` - The hostname of the SFTP server.
    * `port` - The port of the SFTP server.
    * `username` - The username to log in to the SFTP server with.
    * `password` - The password to log in to the SFTP server with.

  Returns a `%SftpStore` struct containing the following:
    - `pid`: The PID for communicating with the SFTP server.
    - `connection`: An opaque data type representing the connection between the
        SFTP client and the SFTP server.
  """
  def sftp_store(host, port, username, password) do
    username = String.to_charlist(username)
    password = String.to_charlist(password)

    :ssh.start()

    {:ok, pid, connection} =
      :ssh_sftp.start_channel(
        host,
        port,
        silently_accept_hosts: true,
        user: username,
        password: password
      )

    %SftpStore{pid: pid, connection: connection}
  end

  @doc """
  Returns the list of paths to parent directories of the path segments.

  ## Examples:

      iex> alias Matryoshka.Impl.SftpStore
      iex> alias Matryoshka.Reference
      iex> ref = "foo/bar/baz"
      iex> Reference.path_segments(ref) |> SftpStore.parent_dirs()
      ["foo", "foo/bar"]
  """
  def parent_dirs(path_segments) do
    # This function lets us pull all the parents from a path reference, so that
    # we can make them in the underlying SFTP directory.
    {paths, _acc} =
      path_segments
      # We don't want to make the last path segment as a directory,
      # that'll be the filename.
      |> Enum.drop(-1)
      |> Enum.map_reduce(
        [],
        fn segment, acc -> {[segment | acc], [segment | acc]} end
      )

    paths
    # Reverse the paths
    |> Enum.map(&Enum.reverse/1)
    # Then recombine them into paths with forward-slash delimiters
    |> Enum.map(&Enum.join(&1, "/"))
  end

  defimpl Matryoshka.Storage do
    def fetch(store, ref) do
      value =
        case :ssh_sftp.read_file(
               store.pid,
               String.to_charlist(ref)
             ) do
          {:ok, bin} -> {:ok, :erlang.binary_to_term(bin)}
          {:error, :no_such_file} -> {:error, {:no_ref, ref}}
          {:error, other} -> {:error, other}
        end

      {store, value}
    end

    def get(store, ref) do
      ref = String.to_charlist(ref)

      value =
        case :ssh_sftp.read_file(store.pid, ref) do
          {:ok, bin} -> :erlang.binary_to_term(bin)
          {:error, _reason} -> nil
        end

      {store, value}
    end

    def put(store, ref, value) do
      # Make sure that parent directories exist
      segments = Reference.path_segments(ref)

      if length(segments) > 1 do
        dirs = SftpStore.parent_dirs(segments)

        Enum.each(
          dirs,
          fn dir -> :ssh_sftp.make_dir(store.pid, dir) end
        )
      end

      # Write value
      :ssh_sftp.write_file(
        store.pid,
        String.to_charlist(ref),
        :erlang.term_to_binary(value)
      )

      store
    end

    def delete(store, ref) do
      :ssh_sftp.delete(
        store.pid,
        String.to_charlist(ref)
      )

      store
    end
  end
end
