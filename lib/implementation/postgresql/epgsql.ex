defrecord Migrations.PostgreSQL.EPgSQL, host: "localhost",
                                        username: nil, password: "",
                                        database: nil, ssl: false, conn: nil do

  alias :pgsql, as: C

  def connect(__MODULE__[host: host, username: username, password: password,
             database: database, ssl: ssl] = t) do
    {:ok, conn} = C.connect(to_char_list(host), to_char_list(username),
                            to_char_list(password),
                            ssl: ssl, database: to_char_list(database))
    t.conn(conn)
  end

  def connect(opts) do
    new(opts).connect
  end

end

defimpl Migrations.Implementation, for: Migrations.PostgreSQL.EPgSQL do

  alias Migrations.PostgreSQL.EPgSQL, as: T
  alias :pgsql, as: C

  def init(T[conn: conn] = t) do
    {:ok, _, _} = C.squery conn, """
                           CREATE TABLE IF NOT EXISTS migrations (
                             id VARCHAR(255) PRIMARY KEY,
                             ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                           )
                           """
    t
  end

  def migrations(T[conn: conn]) do
    {:ok, _, migrations} = C.squery(conn, "SELECT id, ts FROM migrations ORDER BY id DESC")
    lc {id, ts} inlist migrations do
      Migrations.Migration.new(id: id, timestamp: ts)
    end
  end

  def add!(T[conn: conn], Migrations.Migration[id: id]) do
    {:ok, 1} = C.equery(conn,"INSERT INTO migrations (id) VALUES ($1)",[id])
    :ok
  end

  def remove!(T[conn: conn], Migrations.Migration[id: id]) do
    {:ok, _} = C.equery(conn,"DELETE FROM migrations WHERE id = $1",[id])
    :ok
  end

  def execute!(T[conn: conn], m,f,a) do
    C.squery(conn, "BEGIN")
    try do
      apply(m,f,a)
      C.squery(conn, "COMMIT")
    rescue e ->
      C.squery(conn, "ROLLBACK")
      raise(e)
    end
  end

end