defmodule Aruspex.Var do
  @opaque t :: %__MODULE__{
    binding: any,
    domain: domain,
    cost: cost
  }

  @type domain :: Enum.t
  @type cost :: number
  @type name :: Literals

  defstruct binding: nil, domain: [], cost: 0

  @spec domain(t) :: domain
  def domain(var) do
    var.domain
  end

  @spec binding(t) :: any
  def binding(var) do
    var.binding
  end

  @spec bind(t, any) :: t
  def bind(var, value) do
    put_in var.binding, value
  end

  @spec set_cost(t, cost) :: t
  def set_cost(var, cost) do
    put_in(var.cost, cost)
  end

  @spec new(domain) :: t
  def new(domain) do
    %__MODULE__{domain: domain}
  end
end
