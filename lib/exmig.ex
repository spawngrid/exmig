defmodule Migrations do
  @moduledoc """

  Migrations module allows to define a sequence of upgrade/downgrade
  migrations, typically database alterations.

  It is important to preserve the order of ups and downs throughout the
  lifetime of the module.

  See documentation for `up` and `down` macros.

  ## Example

    defmodule MyMigrations do
      use Migrations

      up "first migration" do
        # ...
      end
      down do
        # ...
      end
    end
  """

  defrecord Migration, id: nil, timestamp: nil

  defmacro __using__(_opts) do
    quote do
      import Migrations
      Module.register_attribute __MODULE__, :migrations, persist: true, accumulate: true
      @before_compile Migrations
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def upgrade(_, _), do: nil
      def downgrade(_, _), do: nil
    end
  end

  @doc """
  `up` macro defines an upgrade migration. It will always require
  a body and either a name, or both a name and target instance
  (such as Migrations.ETS or Migrations.PostgreSQL.EPgSQL)

  It will raise ArgumentError if a migration with the same name
  is already defined in the module.

  ## Examples

    up "first table" do
    end

    up "first table", conn do
    end

  """
  defmacro up(name, state // (quote do: _state), body) do
    quote do
      if Enum.member?(@migrations, unquote(name)) do
        raise ArgumentError, message: "upgrade '#{unquote(name)}' already exists"
      end
      def upgrade(unquote(name), unquote(state)), unquote(body)
      @migrations unquote(name)
      @current_migration nil
    end
  end

  @doc """
  `down` macro defines a downgrade migration. It will always require
  a body and either no arugments, or a name, or both a name and target instance
  (such as Migrations.ETS or Migrations.PostgreSQL.EPgSQL)

  It will raise ArgumentError if a migration with the same name
  is already defined in the module.

  Unlike in `up`, one can use `down` without a name, and it will use the latest
  defined `up` as a source of the migration name.

  ## Examples

    up "first table" do
    end
    down do
    end

    up "second table", conn do
    end
    down conn do
    end

    up "third table", conn do
    end
    down "third table", conn do
    end

  """
  defmacro down(state // (quote do: _state), body) when not is_binary(state) do
    quote do
      unless nil?(@current_migration) do
        raise ArgumentError, message: "downgrade '#{@current_migration}' already exists"
      end
      @current_migration hd(@migrations)
      def downgrade(@current_migration, unquote(state)), unquote(body)
    end
  end

  defmacro down(name, body) when is_binary(name) do
    quote do
      unless nil?(@current_migration) do
        raise ArgumentError, message: "downgrade '#{@current_migration}' already exists"
      end
      @current_migration unquote(name)
      def downgrade(unquote(name), _state), unquote(body)
    end
  end

  defmacro down(name, state, body) do
    quote do
      unless nil?(@current_migration) do
        raise ArgumentError, message: "downgrade '#{@current_migration}' already exists"
      end
      @current_migration unquote(name)
      def downgrade(unquote(name), unquote(state)), unquote(body)
    end
  end

  @doc """
  Returns all migrations in the module
  """
  def all(module) do
    lc {:migrations, [id]} inlist module.__info__(:attributes) do
      Migration.new(id: id)
    end
  end

  alias Migrations.Implementation, as: I

  @type upgrade_result :: :up_to_date | {:upgrade, [Migration.t]} | {:downgrade, [Migration.t]}
  @doc """
  Migrates according to the module
  """
  @spec migrate(module, term) :: upgrade_result
  @spec migrate(module, term, term) :: upgrade_result
  def migrate(module, instance) do
    do_migrate(module, migration_path(module, instance))
  end
  @doc """
  Migrates according to the module, up or down to a specific
  version
  """
  def migrate(module, version, instance) do
    do_migrate(module, migration_path(module, version, instance))
  end

  defp do_migrate(_module, {_instance, :up_to_date}), do: :up_to_date
  defp do_migrate(module, {instance, {:upgrade, path} = migration}) do
    lc m inlist path do
      I.execute!(instance, module, :upgrade, [m.id, instance])
      I.add!(instance, m)
    end
    migration
  end
  defp do_migrate(module, {instance, {:downgrade, path} = migration}) do
    lc m inlist path do
      I.execute!(instance, module, :downgrade, [m.id, instance])
      I.remove!(instance, m)
    end
    migration
  end


  defp migration_path(module, instance) do
    last_version = all(module) |> Enum.reverse |> Enum.first
    case last_version do
      nil -> :up_to_date
      Migration[id: version] ->
        migration_path(module, version, instance)
    end
  end

  defp migration_path(module, version, instance) do
    instance = I.init(instance)
    migrations = Enum.drop_while(Enum.reverse(all(module)), fn(x) -> x.id != version end) |>
                 Enum.reverse
    current_migrations = I.migrations(instance) |>
                         Enum.sort(fn(x, y) -> x.timestamp > y.timestamp end) |>
                         Enum.map(fn(x) -> x.id end)
    result =
    case current_migrations do
      [^version|_] -> :up_to_date
      [] ->
        # full upgrade path
        path = migrations
        {:upgrade, path}
      [last_version|_] ->
        if Enum.member?(migrations, Migration.new(id: last_version)) do
          path = Enum.drop_while(migrations, fn(Migration[id: id]) -> id != last_version end)
          {:upgrade, tl(path)}
        else
          path = Enum.take_while(Enum.reverse(all(module)), fn(Migration[id: id]) -> id != version end)
          {:downgrade, path}
        end
    end
    {instance, result}
  end

end
