defmodule ContactosApp.CRM.Contact do
  use Ash.Resource, domain: ContactosApp.CRM, data_layer: AshPostgres.DataLayer

  postgres do
    table "contacts"
    repo ContactosApp.Repo
  end

  actions do
    defaults [:read, :destroy, update: :*]
    create :create, accept: [:first_name, :last_name, :company, :email, :whatsapp_phone]
  end

  attributes do
    uuid_primary_key :id
    attribute :first_name, :string, allow_nil?: false
    attribute :last_name, :string, allow_nil?: false
    attribute :company, :string
    attribute :email, :string, allow_nil?: false
    attribute :whatsapp_phone, :string, allow_nil?: false
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  identities do
    identity :unique_email, [:email]
  end
end
