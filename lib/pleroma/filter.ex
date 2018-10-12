defmodule Pleroma.Filter do
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias Pleroma.{User, Repo, Activity}

  @primary_key false
  schema "filters" do
    belongs_to(:user, Pleroma.User, primary_key: true)
    field(:filter_id, :id, primary_key: true)
    field(:hide, :boolean, default: false)
    field(:whole_word, :boolean, default: true)
    field(:phrase, :string)
    field(:context, {:array, :string})
    field(:expires_at, :utc_datetime)

    timestamps()
  end

  def get(id, %{id: user_id} = _user) do
    query =
      from(
        f in Pleroma.Filter,
        where: f.filter_id == ^id,
        where: f.user_id == ^user_id
      )

    Repo.one(query)
  end

  def get_filters(%Pleroma.User{id: user_id} = user) do
    query =
      from(
        f in Pleroma.Filter,
        where: f.user_id == ^user_id
      )

    Repo.all(query)
  end

  def create(%Pleroma.Filter{} = filter) do
    Repo.insert(filter)
  end

  def delete(%Pleroma.Filter{} = filter) do
    Repo.delete(filter)
  end

  def update(%Pleroma.Filter{} = filter) do
    destination = Map.from_struct(filter)

    Pleroma.Filter.get(filter.filter_id, %{id: filter.user_id})
    |> cast(destination, [:phrase, :context, :hide, :expires_at, :whole_word])
    |> Repo.update()
  end
end
