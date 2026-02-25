defmodule ContactosApp.CRM do
  use Ash.Domain

  resources do
    resource ContactosApp.CRM.Contact
    resource ContactosApp.CRM.MessageTemplate
    resource ContactosApp.CRM.MessageLog
    resource ContactosApp.CRM.CallLog
  end
end
