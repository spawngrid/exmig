defrecord Migrations.DBI, for: nil, table: "migrations", transact: true

defprotocol Migration.DBI.SQL do
  @type t
  @type result :: {DBI.statement, DBI.bindings}

  @spec begin(t) :: result
  def begin(t)

  @spec commit(t) :: result
  def commit(t)

  @spec rollback(t) :: result
  def rollback(t)

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

  def execute!(T[for: for, transact: transact], m,f,a) do
    if transact do
      DBI.query!(for, "BEGIN")
    end
    {query, bindings} = Migration.DBI.SQL.begin(for)
    DBI.query!(for, query, bindings)
    try do
      apply(m,f,a)
      {query, bindings} = Migration.DBI.SQL.commit(for)
      DBI.query!(for, query, bindings)
      if transact do
        DBI.query!(for, "COMMIT")
      end
    rescue e ->
      {query, bindings} = Migration.DBI.SQL.rollback(for)
      DBI.query!(for, query, bindings)
      if transact do
        DBI.query!(for, "ROLLBACK")
      end
      raise(e)
    end
  end

end