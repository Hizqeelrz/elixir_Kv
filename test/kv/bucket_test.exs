defmodule KV.BucketTest do
  use ExUnit.Case, async: true

  # start_supervised is used that it guarantee that the process shutdown before the next test starts. i.e it helps of one test not to interfere with the other test

  setup do
    bucket = start_supervised!(KV.Bucket)
    # {:ok, bucket} = KV.Bucket.start_link(fn -> %{} end)
    %{bucket: bucket}
  end

  test "stores values by key", %{bucket: bucket} do
    assert KV.Bucket.get(bucket, "milk") == nil

    KV.Bucket.put(bucket, "milk", 3)
    assert KV.Bucket.get(bucket, "milk") == 3
  end
end

#NOTES
# Agent process stores the current process in the pid and maintain state we can get the value update the value for that firstly start the agent with start_link and then update the value as desired
# we can also name agents with atoms but as they
#GenServer are used for sending and receiving information from server/client ----------- process is same start_link---- we can implement client server with 2 different modules or can combine them in 1 module diff func of GenServer are call, cast etc...
