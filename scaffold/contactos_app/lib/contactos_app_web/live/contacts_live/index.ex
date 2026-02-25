defmodule ContactosAppWeb.ContactsLive.Index do
  use ContactosAppWeb, :live_view
  alias ContactosApp.CRM.Contact

  def mount(_, _, socket), do: {:ok, assign(socket, contacts: Ash.read!(Contact))}

  def handle_event("delete", %{"id" => id}, socket) do
    id |> Ash.get!(Contact) |> Ash.destroy!()
    {:noreply, assign(socket, contacts: Ash.read!(Contact))}
  end

  def render(assigns) do
    ~H"""
    <h1>Contactos</h1>
    <.link navigate={~p"/contacts/new"}>Nuevo</.link>
    <ul>
      <li :for={c <- @contacts}>
        {c.first_name} {c.last_name} - {c.email}
      </li>
    </ul>
    """
  end
end
