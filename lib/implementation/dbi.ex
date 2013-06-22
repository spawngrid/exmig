defrecord Migrations.DBI, for: nil

defprotocol Migration.DBI.SQL do
  @type t
  @type result :: {DBI.statement, DBI.bindings}

  @spec init(t) :: result
  def init(t)

  @spec list(t) :: result
  def list(t)

  @spec add(t, Migrations.Migration.t) :: result
  def add(t, migration)

  @spec remove(t, Migrations.Migration.t) :: result
  def remove(t, migration)
end

defimpl Migrations.Implementation, for: Migrations.DBI do

  alias Migrations.DBI, as: T

  def init(T[for: for] = t) do
    {query, bindings} = Migration.DBI.SQL.init(for)
    DBI.query!(for, query, bindings)
    t
  end

  def migrations(T[for: for]) do
    {query, bindings} = Migration.DBI.SQL.list(for)
    migrations = DBI.query!(for, query, bindings)
    lc {id, ts} inlist Enum.to_list(migrations) do
      Migrations.Migration.new(id: id, timestamp: ts)
    end
  end

  def add!(T[for: for], migration) do
    {query, bindings} = Migration.DBI.SQL.add(for, migration)
    DBI.Result[count: 1] = DBI.query!(for, query, bindings)
    :ok
  end

  def remove!(T[for: for], migration) do
    {query, bindings} = Migration.DBI.SQL.remove(for, migration)
    DBI.query!(for, query, bindings)
    :ok
  end

  def execute!(T[for: for], m,f,a) do
    DBI.query!(for, "BEGIN")
    try do
      apply(m,f,a)
      DBI.query!(for, "COMMIT")
    rescue e ->
      DBI.query!(for, "ROLLBACK")
      raise(e)
    end
  end

end