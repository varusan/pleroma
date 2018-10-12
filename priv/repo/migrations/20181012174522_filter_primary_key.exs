defmodule Pleroma.Repo.Migrations.FilterPrimaryKey do
  use Ecto.Migration

  def change do
    # FIXME: Avoid dropping the table
    drop table(:filters)

    create table(:filters, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all), primary_key: true
      add :filter_id, :id, primary_key: true
      add :hide, :boolean
      add :phrase, :string
      add :context, {:array, :string}
      add :expires_at, :datetime
      add :whole_word, :boolean

      timestamps()
    end
  end
end
