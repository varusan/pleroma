defmodule Pleroma.Repo.Migrations.ReferenceActors do
  use Ecto.Migration

  def change do
    alter table(:activities) do
      modify(:actor, references(:users, column: :ap_id, on_delete: :delete_all, type: :string))
    end
  end
end
