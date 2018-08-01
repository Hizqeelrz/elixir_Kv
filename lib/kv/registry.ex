defmodule KV.Registry do
  use GenServer

  # for Client API

  @doc """
  Starts the registry for the GenServer
  """

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Look up for the name in the server, send the request to server and wait until response come
  This is Synchronous call
  Returns `{:ok, pid}` if the name exist,`:error` ottherwise.
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
    {:ok, %{}}
  end

  @doc """
  Handles the lookup call from the client the second argument tuple should be the first argument for the handle_call function returns `{:reply, reply, new_state}`
  Fetches the value for the specific key required
  """

  def handle_call({:lookup, name}, _from, names) do
    {:reply, Map.fetch(names, name), names}
  end

  @doc """
  Handles the cast request with the current server state with `{:no_reply, new_state}`
  """

  def handle_cast({:create, name}, names) do
    if Map.has_key?(names, name) do
      {:no_reply, names}
    else
      {:ok, bucket} = KV.Bucket.start_link([])
      {:no_reply, Map.put(names, name, bucket)}
    end
  end

end
