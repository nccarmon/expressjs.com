defmodule ContactosAppWeb.DashboardLive do
  use ContactosAppWeb, :live_view
  alias ContactosApp.CRM.{Contact, MessageLog, CallLog}

  def mount(_, _, socket) do
    {:ok,
     assign(socket,
       contacts: Ash.count!(Contact),
       messages: Ash.count!(MessageLog),
       calls: Ash.count!(CallLog)
     )}
  end

  def render(assigns) do
    ~H"""
    <h1>Dashboard CRM</h1>
    <ul>
      <li>Contactos: {@contacts}</li>
      <li>Mensajes: {@messages}</li>
      <li>Llamadas: {@calls}</li>
    </ul>
    """
  end
end
