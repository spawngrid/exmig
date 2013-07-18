defimpl Migration.DBI.SQL, for: DBI.PostgreSQL do

  def begin(_) do
    {"SAVEPOINT exmig", []}
  end

  def commit(_) do
    {"RELEASE SAVEPOINT exmig", []}
  end

  def rollback(_) do
    {"ROLLBACK TO exmig", []}
  end

  def init(_, Migrations.DBI[table: table]) do
    {""", []}
       CREATE TABLE IF NOT EXISTS #{table} (
         id VARCHAR(255) PRIMARY KEY,
         ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP
       )
    """
  end

  def list(_, Migrations.DBI[table: table]) do
    {"SELECT id, ts FROM #{table} ORDER BY id DESC", []}
  end

  def add(_, Migrations.Migration[id: id], Migrations.DBI[table: table]) do
    {"INSERT INTO #{table} (id) VALUES (:{id})",[id: id]}
  end

  def remove(_, Migrations.Migration[id: id], Migrations.DBI[table: table]) do
    {"DELETE FROM #{table} WHERE id = :{id}",[id: id]}
  end


end
