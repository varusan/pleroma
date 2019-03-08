defmodule Pleroma.Repo.Migrations.CreatePollVote do
  use Ecto.Migration

  def change do
    create table(:poll_votes) do
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all)
      add :poll_id, references(:polls, on_delete: :delete_all)
      add :choice, :integer

      timestamps()
    end
  end
end
