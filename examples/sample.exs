db = Migrations.PostgreSQL.EPgSQL.connect(database: "test", username: "test")

defmodule SampleMigrations do
  use Migrations
  alias Migrations.PostgreSQL.EPgSQL, as: P

  up "users table", P[] = p do
    {:ok, _, _} = :pgsql.squery(p.conn, """)
    CREATE TABLE users (
      email VARCHAR(255) NOT NULL PRIMARY KEY,
      password VARCHAR(255) NOT NULL
    )
    """
  end

  down P[] = p do
    {:ok, _} = :pgsql.squery(p.conn, """)
    DROP TABLE users
    """
  end
end

Migrations.migrate SampleMigrations, db