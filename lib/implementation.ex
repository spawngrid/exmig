defprotocol Migrations.Implementation do
  @type t
  @type state

  @spec init(t) :: t
  def init(impl)

  @spec migrations(t) :: [Migrations.Migration.t]
  def migrations(impl)

  @spec add!(t, Migrations.Migration.t) :: :ok
  def add!(impl, migration)

  @spec remove!(t, Migrations.Migration.t) :: :ok
  def remove!(impl, migration)

  @spec execute!(t, module, atom, [any]) :: :ok
  def execute!(t, m, f, a)
end