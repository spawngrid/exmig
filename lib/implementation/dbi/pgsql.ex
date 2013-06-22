defimpl Migration.DBI.SQL, for: DBI.PostgreSQL do

  def init(_) do
    {""", []}
       CREATE TABLE IF NOT EXISTS migrations (
         id VARCHAR(255) PRIMARY KEY,
         ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP
       )
    """
  end

  def list(_) do
    {"SELECT id, ts FROM migrations ORDER BY id DESC", []}
  end

  def add(_, Migrations.Migration[id: id]) do
    {"INSERT INTO migrations (id) VALUES (:{id})",[id: id]}
  end

  def remove(_, Migrations.Migration[id: id]) do
    {"DELETE FROM migrations WHERE id = :{id}",[id: id]}
  end


end
