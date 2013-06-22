db = DBI.PostgreSQL.connect!(database: "test", username: "test")

defmodule SampleMigrations do
  use Migrations

  alias Migrations.DBI, as: I

  up "users table", I[for: db] do
    DBI.query!(db, """)
    CREATE TABLE users (
      email VARCHAR(255) NOT NULL PRIMARY KEY,
      password VARCHAR(255) NOT NULL
    )
    """
  end

  down I[for: db] do
    DBI.query!(db, "DROP TABLE users")
  end

  up "drop users", I[for: db] do
    downgrade("users table", db)
  end
end

Migrations.migrate SampleMigrations, Migrations.DBI.new(for: db)