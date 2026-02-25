defmodule ContactosApp.CRM.MessageTemplate do
  use Ash.Resource, domain: ContactosApp.CRM, data_layer: AshPostgres.DataLayer

  postgres do
    table "message_templates"
    repo ContactosApp.Repo
  end

  actions do
    defaults [:read, :destroy, update: :*]
    create :create, accept: [:name, :body]
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :body, :string, allow_nil?: false
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end
end
