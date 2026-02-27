defmodule Life.Queue.Server do
  @moduledoc false
  use GenServer

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, %Life.Queue{}}
  end

  @impl true
  def handle_cast({:enqueue, item}, %Life.Queue{items: items} = state) do
    {:noreply, %Life.Queue{state | items: items ++ [item]}}
  end

  @impl true
  def handle_call(:dequeue, _, %Life.Queue{items: []} = state) do
    {:reply, nil, state}
  end

  @impl true
  def handle_call(:dequeue, _, %Life.Queue{items: [head | tail]} = state) do
    {:reply, head, %Life.Queue{state | items: tail}}
  end

  @impl true
  def handle_call(:peek, _, %Life.Queue{items: []} = state) do
    {:reply, nil, state}
  end

  @impl true
  def handle_call(:peek, _, %Life.Queue{items: [head | _]} = state) do
    {:reply, head, state}
  end

  @impl true
  def handle_call(:size, _, %Life.Queue{items: items} = state) do
    {:reply, length(items), state}
  end

  @impl true
  def handle_call(:empty?, _, %Life.Queue{items: items} = state) do
    {:reply, items == [], state}
  end
end
