defmodule Aruspex do
  import Enum, only: [reduce: 3]

  use ExActor.GenServer
  use PatternTap
  use Exyz

  defmodule Var do
    defstruct binding: nil, constraints: [], domain: [], cost: 0
    @type constraint :: ((any, any) -> boolean)
    @type t :: %Var{binding: any, domain: Enum.t }
  end

  defmodule State do
    defstruct constraints: [], variables: %{}
  end

  defstart start_link, gen_server_opts: :runtime do
    initial_state %State{}
  end

  defcast variables(variables), state: state do
    reduce(variables, state, &put_in(&2.variables[&1], %Var{}))
    |> new_state
  end

  defcast domain(variables, domain), state: state do
    reduce(variables, state, &put_in(&2.variables[&1].domain, domain))
    |> new_state
  end

  # v: [variable], c: constraint
  defcast constraint(v, c), state: state do
    update_in(state.constraints, fn constraints ->
      [{v, c}| constraints]
    end)
    |> new_state
  end

  defcall label(), state: state, timeout: :infinity do
    reply Aruspex.SimulatedAnnealing.label(state)
  end

  def energy(state) do
    Enum.sum state.variables, fn var -> var.cost end
  end

  def compute_cost state do
    state = zero_cost state

    apply_constraint = fn (v, c) ->
      apply c, (for x <- v, do: state.variables[x].binding)
    end

    Enum.reduce state.constraints, state, fn {v, c}, state ->
      cost = apply_constraint.(v, c)
      add_cost(state, v, cost)
    end
  end

  def variable_names state do
    Dict.keys state.variables
  end

  def zero_cost state do
    set_cost state, variable_names(state), 0
  end

  def add_cost state, [], _cost do
    state
  end

  def add_cost state, [h|t], cost do
    add_cost(state, h, cost)
    |> add_cost(t, cost)
  end

  def add_cost state, v, cost do
    update_in(state.variables[v].cost, &(&1 + cost))
  end

  def set_cost state, [], _cost do
    state
  end

  def set_cost state, [h|t], cost do
    set_cost(state, h, cost)
    |> set_cost(t, cost)
  end

  def set_cost state, v, cost do
    put_in(state.variables[v].cost, cost)
  end
end
