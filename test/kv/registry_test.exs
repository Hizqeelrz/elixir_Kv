defmodule KV.RegistryTest do
  use ExUnit.Case, async: true

  # registry require :name option as an argument instead of PID so startup changed

  setup context do
    _ = start_supervised!({KV.Registry, name: context.test})
    %{registry: context.test}
  end

  test "spawns buckets", %{registry: registry} do
    assert KV.Registry.lookup(registry, "shopping") == :error

    KV.Registry.create(registry, "shopping")
    assert {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    KV.Bucket.put(bucket, "peaches", 1)
    assert KV.Bucket.get(bucket, "peaches") == 1
  end

  test "removes bucket on exit", %{registry: registry} do
    KV.Registry.create(registry, "shopping")
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")
    Agent.stop(bucket)

    # ensures that registry processed with DOWN message
    _ = KV.Registry.create(registry, "bogus")
    assert KV.Registry.lookup(registry, "shopping") == :error
  end

  test "removes bucket on crash", %{registry: registry} do
    KV.Registry.create(registry, "shopping")
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    # Stops the bucket with non-normal(i.e :shutdown) reason
    # if process terminates otherthan :normal reason than all linked process EXIT
    Agent.stop(bucket, :shutdown)

    _ = KV.Registry.create(registry, "bogus")
    # After stoping the process the linked process i.e GenServer.call/3 also stops
    assert KV.Registry.lookup(registry, "shopping") == :error
  end
end
