defmodule Pleroma.Repo.Migrations.AddBookmarkssToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :bookmarks, {:array, :string}
    end

    create index(:users, [:bookmarks], using: :gin)
  end
end
