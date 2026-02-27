defmodule Life.Queue do
  @moduledoc """
  A simple queue implementation using a genserver.

  Public API functions live in this module and delegate to
  `Life.Queue.Server`, which implements the GenServer.
  """

  defstruct items: []

  @doc """
  Start the queue server. Intended for use in a supervisor child spec.
  """
  def start_link(arg) do
    Life.Queue.Server.start_link(arg)
  end

  @doc false
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  @doc """
  Add an item to the queue.
  """
  def enqueue(item) do
    GenServer.cast(Life.Queue.Server, {:enqueue, item})
  end

  @doc """
  Remove an item from the queue.
  """
  def dequeue do
    GenServer.call(Life.Queue.Server, :dequeue)
  end

  @doc """
  Get the next item in the queue without removing it.
  """
  def peek do
    GenServer.call(Life.Queue.Server, :peek)
  end

  @doc """
  Get the number of items in the queue.
  """
  def size do
    GenServer.call(Life.Queue.Server, :size)
  end

  @doc """
  Check if the queue is empty.
  """
  def empty? do
    GenServer.call(Life.Queue.Server, :empty?)
  end
end
