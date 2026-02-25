defmodule ContactosApp.Repo.Migrations.CreateContacts do
  use Ecto.Migration

  def change do
    create table(:contacts, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :first_name, :text, null: false
      add :last_name, :text, null: false
      add :company, :text
      add :email, :text, null: false
      add :whatsapp_phone, :text, null: false
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:contacts, [:email])
  end
end
