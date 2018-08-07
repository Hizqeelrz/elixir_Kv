defmodule KV.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  # passing directly here because it do not require any child during initialization
  # we can give DynamicSupervisor child at the time of calling
  # i.e DynamicSupervisor.start_child(KV.BucketSupervisor, any_child_to_be_started)
  def init(:ok) do
    children = [
      {KV.Registry, name: KV.Registry},
      {DynamicSupervisor, name: KV.BucketSupervisor, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
