defmodule Life.Worker.Boundary do
  @callback new(pos_integer(), pos_integer()) :: Life.Core.t()
  @callback evolve(Life.Core.t()) :: Life.Core.t()
  @callback render(Life.Core.t()) :: String.t()
  @callback publish(String.t()) :: any()
  @callback schedule_tick(pid(), non_neg_integer()) :: reference()
end
