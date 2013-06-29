defrecord Migrations.DBI, for: nil, table: "migrations"

defprotocol Migration.DBI.SQL do
  @type t
  @type result :: {DBI.statement, DBI.bindings}

  @spec init(t, Migrations.DBI.t) :: result
  def init(t, dbi)

  @spec list(t, Migrations.DBI.t) :: result
  def list(t, dbi)

  @spec add(t, Migrations.Migration.t, Migrations.DBI.t) :: result
  def add(t, migration, dbi)

  @spec remove(t, Migrations.Migration.t, Migrations.DBI.t) :: result
  def remove(t, migration, dbi)
end

defimpl Migrations.Implementation, for: Migrations.DBI do

  alias Migrations.DBI, as: T

  def init(T[for: for] = t) do
    {query, bindings} = Migration.DBI.SQL.init(for, t)
    DBI.query!(for, query, bindings)
    t
  end

  def migrations(T[for: for] = t) do
    {query, bindings} = Migration.DBI.SQL.list(for, t)
    migrations = DBI.query!(for, query, bindings)
    lc {id, ts} inlist Enum.to_list(migrations) do
      Migrations.Migration.new(id: id, timestamp: ts)
    end
  end

  def add!(T[for: for] = t, migration) do
    {query, bindings} = Migration.DBI.SQL.add(for, migration, t)
    DBI.Result[count: 1] = DBI.query!(for, query, bindings)
    :ok
  end

  def remove!(T[for: for] = t, migration) do
    {query, bindings} = Migration.DBI.SQL.remove(for, migration, t)
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