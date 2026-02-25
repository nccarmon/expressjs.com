defmodule ContactosApp.Repo.Migrations.CreateMessageTemplates do
  use Ecto.Migration

  def change do
    create table(:message_templates, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :text, null: false
      add :body, :text, null: false
      timestamps(type: :utc_datetime_usec)
    end
  end
end
