defmodule Pleroma.Repo.Migrations.CreatePoll do
  use Ecto.Migration

  def change do
    create table(:polls) do
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all)
      add :expires_at, :naive_datetime
      add :options, {:array, :string}, null: false, default: []
      add :cached_tallies, {:array, :integer}, null: false, default: []
      add :multiple, :boolean, null: false, default: false
      add :hide_totals, :boolean, null: false, default: false
      add :votes_count, :integer, null: false, default: 0
      add :last_fetched_at, :naive_datetime

      timestamps()
    end
  end
end
