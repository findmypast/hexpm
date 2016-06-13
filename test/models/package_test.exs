defmodule HexWeb.PackageTest do
  use HexWeb.ModelCase, async: true

  alias HexWeb.User
  alias HexWeb.Package

  setup do
    user =
      User.build(%{username: "eric", email: "eric@mail.com", password: "eric"}, true)
      |> HexWeb.Repo.insert!

    {:ok, user: user}
  end

  test "create package and get", %{user: user} do
    user_id = user.id

    Package.build(user, pkg_meta(%{name: "ecto", description: "DSL"})) |> HexWeb.Repo.insert!
    assert [%User{id: ^user_id}] = HexWeb.Repo.get_by(Package, name: "ecto") |> assoc(:owners) |> HexWeb.Repo.all
    assert is_nil(HexWeb.Repo.get_by(Package, name: "postgrex"))
  end

  test "update package", %{user: user} do
    package = Package.build(user, pkg_meta(%{name: "ecto", description: "DSL"})) |> HexWeb.Repo.insert!

    Package.update(package, %{"meta" => %{"maintainers" => ["eric", "josé"], "description" => "description", "licenses" => ["Apache"]}})
    |> HexWeb.Repo.update!
    package = HexWeb.Repo.get_by(Package, name: "ecto")
    assert length(package.meta.maintainers) == 2
  end

  test "validate blank description in metadata", %{user: user} do
    meta = %{
      "maintainers" => ["eric", "josé"],
      "licenses"     => ["apache", "BSD"],
      "links"        => %{"github" => "www", "docs" => "www"},
      "description"  => ""}

    assert {:error, changeset} = Package.build(user, pkg_meta(%{name: "ecto", meta: meta})) |> HexWeb.Repo.insert
    assert changeset.errors == []
    assert changeset.changes.meta.errors == [description: {"can't be blank", []}]
  end

  test "packages are unique", %{user: user} do
    Package.build(user, pkg_meta(%{name: "ecto", description: "DSL"})) |> HexWeb.Repo.insert!
    assert {:error, _} = Package.build(user, pkg_meta(%{name: "ecto", description: "Domain-specific language"})) |> HexWeb.Repo.insert
  end

  test "reserved names", %{user: user} do
    assert {:error, %{errors: [name: {"is reserved", []}]}} = Package.build(user, pkg_meta(%{name: "elixir", description: "Awesomeness."})) |> HexWeb.Repo.insert
  end
end
