defmodule Pleroma.Repo.Migrations.ReferenceActors do
  use Ecto.Migration

  def change do
    # Clean up first.
    execute(
      "delete from activities where not exists (select 1 from users where users.ap_id = activities.actor)"
    )

    alter table(:activities) do
      modify(:actor, references(:users, column: :ap_id, on_delete: :delete_all, type: :string))
    end
  end
end
