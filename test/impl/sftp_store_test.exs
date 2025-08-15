defmodule MatryoshkaTest.SftpStoreTest do
  alias Matryoshka.Impl.SftpStore
  alias Matryoshka.Storage

  use ExUnit.Case, async: true
  doctest SftpStore

  # When the port is zero, the ssh daemon picks a random free port
  @random_port 0
  @user "user"
  @password "password"

  @moduletag :tmp_dir

  setup context do
    # Set up SFTP server options

    # Where the public keys are saved
    {:ok, cwd} = File.cwd()

    system_dir =
      to_charlist(
        Path.join([
          cwd,
          "test",
          "ssh"
        ])
      )

    user = String.to_charlist(@user)
    password = String.to_charlist(@password)
    root = String.to_charlist(context.tmp_dir)

    options = [
      system_dir: system_dir,
      user_passwords: [
        {user, password}
      ],
      subsystems: [
        :ssh_sftpd.subsystem_spec(root: root)
      ]
    ]

    # Start SFTP server
    :ssh.start()
    {:ok, server_ref} = :ssh.daemon(:loopback, @random_port, options)
    {:ok, daemon_info} = :ssh.daemon_info(server_ref)
    ip = Keyword.get(daemon_info, :ip)
    port = Keyword.get(daemon_info, :port)
    {:ok, ip, port}

    # Start SftpStore (SFTP Client)
    sftp_store = SftpStore.sftp_store(ip, port, @user, @password)

    # Close SFTP server when test is done
    on_exit(fn ->
      :ssh.stop_daemon(server_ref)
    end)

    {:ok, store: sftp_store}
  end

  test "Get on empty SftpStore returns nil", %{store: store} do
    # Act
    {_new_store, value} = Storage.get(store, "item")

    # Assert
    assert value == nil
  end

  test "Get on empty SftpStore doesn't change SftpStore", %{store: store} do
    # Act
    {new_store, _value} = Storage.get(store, "item")

    # Assert
    assert store == new_store
  end

  test "Fetch on empty SftpStore returns no_ref error", %{store: store} do
    # Act
    {_new_store, value} = Storage.fetch(store, "item")

    # Assert
    assert value == {:error, {:no_ref, "item"}}
  end

  test "Fetch on empty SftpStore doesn't change SftpStore", %{store: store} do
    # Act
    {new_store, _value} = Storage.fetch(store, "item")

    # Assert
    assert store == new_store
  end

  test "Putting an item into a SftpStore then getting it returns the same value", %{store: store} do
    # Act
    store = Storage.put(store, "item", :item)
    {_store, value} = Storage.get(store, "item")

    assert :item == value
  end

  test "Deleting on an empty SftpStore doesn't change the SftpStore", %{store: store} do
    # Act
    new_store = Storage.delete(store, "item")

    # Assert
    assert store == new_store
  end

  test "Putting an item with a compound reference into a SftpStore, then getting it, returns the same value", %{store: store} do
    store = Storage.put(store, "foo/bar/baz", :qux)
    {_store, value} = Storage.fetch(store, "foo/bar/baz")

    assert value == {:ok, :qux}
  end
end
