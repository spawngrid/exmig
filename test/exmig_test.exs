Code.require_file "test_helper.exs", __DIR__

defmodule MigrationsTest do
  use ExUnit.Case

  defmodule M do
    use Migrations

    up "first table" do
      :ets.new(:test_table, [:public, :named_table])
      :ets.insert(:test_table, {:test, :passed})
    end

    up "second table", do: nil
    down do: nil

    up "third table", do: nil
    down "third table", do: nil

    up "fourth table", state, do: state
    down state, do: state

  end

  defmodule M0 do
    use Migrations

    up "first table", do: nil

    up "second table", do: nil
    down do: nil

    up "third table", do: nil
    down "third table", do: nil

    up "fourth table", state, do: state
    down state, do: state

    up "fifth table", do: nil
    up "sixth table", do: nil

  end

  defmodule M1 do
    use Migrations, prefix: MigrationsTest.M

    up "first table", do: nil

    up "second table", do: nil
    down do: nil

    up "third table", do: nil
    down "third table", do: nil

    up "fourth table", state, do: state
    down state, do: state

    up "fifth table", do: nil
    up "sixth table", do: nil

  end
  test "list migrations" do
    assert Migrations.all(M) ==
      Enum.map(["first table", "second table", "third table",
                "fourth table"],
                fn(id) -> Migrations.Migration.new(id: "MigrationsTest.M: #{id}") end)
  end

  test "fail on duplicate upgrades" do
    quoted = quote do
      use Migrations

      up "migration", do: nil
      up "migration", do: nil
    end
    assert_raise ArgumentError, "upgrade 'Test: migration' already exists", fn -> Module.create Test, quoted, __ENV__ end
    :code.delete(Test) ; :code.purge(Test)
  end

  test "fail on duplicate nameless downgrades" do
    quoted = quote do
      use Migrations

      up "migration", do: nil
      down do: nil
      down do: nil
    end
    assert_raise ArgumentError, "downgrade 'Test: migration' already exists", fn -> Module.create Test, quoted, __ENV__ end
    :code.delete(Test) ; :code.purge(Test)
  end

  test "fail on duplicate downgrades" do
    quoted = quote do
      use Migrations

      up "migration", do: nil
      down "migration", do: nil
      down "migration", do: nil
    end
    assert_raise ArgumentError, "downgrade 'Test: migration' already exists", fn -> Module.create Test, quoted, __ENV__ end
    :code.delete(Test) ; :code.purge(Test)
  end

  test "full upgrade" do
    t = Migrations.ETS.create
    assert Migrations.migrate(M, t) == {:upgrade, Migrations.all(M)}
    assert [{:test, :passed}] = :ets.lookup(:test_table, :test)
  end

  test "full independent upgrade" do
    t = Migrations.ETS.create
    assert Migrations.migrate(M, t) == {:upgrade, Migrations.all(M)}
    assert Migrations.migrate(M0, t) == {:upgrade, Migrations.all(M0)}
  end

  test "partial upgrade" do
    t = Migrations.ETS.create
    assert Migrations.migrate(M, t) == {:upgrade, Migrations.all(M)}
    assert Migrations.migrate(M1, t) == {:upgrade, Migrations.all(M1) -- Migrations.all(M)}
  end

  test "partial downgrade" do
    t = Migrations.ETS.create
    assert Migrations.migrate(M, t) == {:upgrade, Migrations.all(M)}
    assert Migrations.migrate(M1, t) == {:upgrade, Migrations.all(M1) -- Migrations.all(M)}
    assert Migrations.migrate(M1, "MigrationsTest.M: fourth table", t) == {:downgrade, Enum.reverse(Migrations.all(M1) -- Migrations.all(M))}
  end

end
