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
  `:name` is required*
  """

  def start_link(opts) do
    #passes the name to GenServer init
    server = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, server, opts)
  end

  @doc """
  Look up for the name in the server, send the request to server and wait until response come
  This is Synchronous call
  Returns `{:ok, pid}` if the name exist,`:error` otherwise.
  """

  def lookup(server, name) do
    # lookup now directly done in ETS rather then accessing the server
    case :ets.lookup(server, name) do
      [{^name, pid}] -> {:ok, pid}
      [] -> :error
    end
    # GenServer.call(server, {:lookup, name})
  end

  @doc """
  This is Asyncchronous call and ensures that the bucket is associated with the given name
  """

  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  # for Server Callbacks

  @doc """
  Reply back to the start link with `{:ok, state}` with the second argument i.e `:ok`
  """

  def init(table) do
    names = :ets.new(table, [:named_table, read_concurrency: true])
    refs = %{}
    {:ok, {names, refs}}
  end

  # @doc """
  # Handles the lookup call from the client the second argument tuple should be the first argument for the handle_call function returns `{:reply, reply, new_state}`
  # Fetches the value for the specific key required
  # """

  #handle_call is disabled because lookup's are now directly handled by ets

  # def handle_call({:lookup, name}, _from, {names, _} = state) do
  #   {:reply, Map.fetch(names, name), state}
  # end

  @doc """
  Handles the cast request with the current server state with `{:noreply, new_state}`
  """

  # DynamicSupervisor is added for starting up bucket dynamically
  # changed handle_cast to handle_call because to guarantee the client will only
  #continue after changes made in the table

  def handle_call({:create, name}, _from, {names, refs}) do

    case lookup(names, name) do
    {:ok, pid} ->
      {:reply, pid, {names, refs}}
    :error ->
      {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, name)
      :ets.insert(names, {name, pid})
      {:reply, pid, {names, refs}}
    end
  end

  @doc """
  used for all other messages, server receive that are not sent by GenServer `call/cast` and which are send by `sent/2` if not handled than cause our registry to crash
  """

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    :ets.delete(names, name)
    {:noreply, {names, refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

end
