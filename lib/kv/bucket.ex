defmodule KV.Bucket do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end)
  end

  def put(bucket, key, value) do
    Agent.update(bucket, &Map.put(&1, key, value))
  end

  def get(bucket, key) do
    Agent.get(bucket, &Map.get(&1, key))
  end
end

# Map.get(fn {key,value} -> key)
# fn map -> Map.get(map) end, key

# &Map.get(&1, key)
