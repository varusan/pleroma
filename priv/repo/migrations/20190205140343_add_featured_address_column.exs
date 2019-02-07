defmodule Pleroma.Repo.Migrations.AddFeaturedAddressColumn do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :featured_address, :string
  end

  create index(:users, [:featured_address])
  
  execute """
    update users set featured_address = concat(ap_id, '/collections/featured') where local = true and featured_address is null;
    """
  end
end
