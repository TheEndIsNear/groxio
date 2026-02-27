# Life

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `life` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:life, "~> 0.1.0"}
  ]
end
```

## Queue modules

The project provides a simple queue implemented as a GenServer. The implementation
has been split into two modules:

- `Life.Queue` — public API and struct. Call `Life.Queue.enqueue/1`,
  `Life.Queue.dequeue/0`, `Life.Queue.peek/0`, `Life.Queue.size/0`, and
  `Life.Queue.empty?/0` from your application code.
- `Life.Queue.Server` — internal GenServer implementation. `Life.Queue.start_link/1`
  delegates to `Life.Queue.Server.start_link/1`.

You can add the queue to your supervision tree either by referencing
`Life.Queue` directly (it implements `child_spec/1`) or by referencing
`Life.Queue.Server` explicitly:

```elixir
children = [
  {Life.Queue, []}
  # or
  # {Life.Queue.Server, []}
]

Supervisor.start_link(children, strategy: :one_for_one)
```


Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/life>.

