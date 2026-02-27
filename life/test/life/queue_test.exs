defmodule Life.QueueTest do
  use ExUnit.Case

  setup do
    drain_queue()
    :ok
  end

  defp drain_queue do
    case Life.Queue.dequeue() do
      nil -> :ok
      _ -> drain_queue()
    end
  end

  test "new queue is empty" do
    assert Life.Queue.empty?()
    assert Life.Queue.size() == 0
    assert Life.Queue.peek() == nil
    assert Life.Queue.dequeue() == nil
  end

  test "enqueue and dequeue follow FIFO order" do
    Life.Queue.enqueue(1)
    Life.Queue.enqueue(2)
    Life.Queue.enqueue(3)

    assert Life.Queue.size() == 3
    assert Life.Queue.peek() == 1

    assert Life.Queue.dequeue() == 1
    assert Life.Queue.dequeue() == 2
    assert Life.Queue.dequeue() == 3

    assert Life.Queue.dequeue() == nil
    assert Life.Queue.empty?()
  end

  test "peek does not remove item" do
    Life.Queue.enqueue(:a)
    assert Life.Queue.peek() == :a
    assert Life.Queue.size() == 1
    assert Life.Queue.dequeue() == :a
  end
end
