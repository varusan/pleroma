defmodule Pleroma.Repo.Migrations.AddGroupField do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :group, :boolean, default: false
    end
  end
end
