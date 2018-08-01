defmodule KV.Registry do
  use GenServer

  # for Client API

  @doc """
  Stops the registry for the GenServer
  """

  def stop(server) do
    GenServer.stop(server)
  end

  @doc """
  Starts the registry for the GenServer
  """

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Look up for the name in the server, send the request to server and wait until response come
  This is Synchronous call
  Returns `{:ok, pid}` if the name exist,`:error` otherwise.
  """

  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  @doc """
  This is Asyncchronous call and ensures that the bucket is associated with the given name
  """

  def create(server, name) do
    GenServer.cast(server, {:create, name})
  end

  # for Server Callbacks

  @doc """
  Reply back to the start link with `{:ok, state}` with the second argument i.e `:ok`
  """

  def init(:ok) do
    names = %{}
    refs = %{}
    {:ok, {names, refs}}
  end

  @doc """
  Handles the lookup call from the client the second argument tuple should be the first argument for the handle_call function returns `{:reply, reply, new_state}`
  Fetches the value for the specific key required
  """

  def handle_call({:lookup, name}, _from, {names, _} = state) do
    {:reply, Map.fetch(names, name), state}
  end

  @doc """
  Handles the cast request with the current server state with `{:noreply, new_state}`
  """

  def handle_cast({:create, name}, {names, refs}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs}}
    else
      {:ok, pid} = KV.Bucket.start_link([])
      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, pid)
      {:noreply, {names, refs}}
    end
  end

  @doc """
  used for all other messages, server receive that are not sent by GenServer `call/cast` and which are send by `sent/2` if not handled than cause our registry to crash
  """

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    names = Map.delete(names, name)
    {:noreply, {names, refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

end
