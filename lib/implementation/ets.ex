defrecord Migrations.ETS, tab: nil do

  def create do
    create(new)
  end

  def create(__MODULE__[] = t) do
    tab = :ets.new(__MODULE__, [])
    t.tab(tab)
  end
end

defimpl Migrations.Implementation, for: Migrations.ETS do

  alias Migrations.ETS, as: T

  def init(T[] = t) do
    t
  end

  def migrations(T[tab: tab]) do
    lc {id, ts} inlist :ets.tab2list(tab) do
      Migrations.Migration.new(id: id, timestamp: ts)
    end
  end

  def add!(T[tab: tab], Migrations.Migration[id: id]) do
    :ets.insert(tab, {id, :erlang.now})
    :ok
  end

  def remove!(T[tab: tab], Migrations.Migration[id: id]) do
    :ets.delete(tab, id)
    :ok
  end

  def execute!(T[tab: tab], m, f, a) do
    backup = :ets.tab2list(tab)
    try do
      apply(m,f,a)
    rescue e ->
      :ets.delete_all_objects(tab)
      :ets.insert(tab, backup)
      raise(e)
    end
    :ok
  end

end