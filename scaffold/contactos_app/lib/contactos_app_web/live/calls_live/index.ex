defmodule ContactosAppWeb.CallsLive.Index do
  use ContactosAppWeb, :live_view

  alias ContactosApp.CRM.{CallLog, Contact}

  def mount(_, _, socket) do
    {:ok,
     assign(socket,
       contacts: Ash.read!(Contact),
       calls: Ash.read!(CallLog),
       form: to_form(%{"direction" => "outbound", "duration_seconds" => "0"}, as: :call)
     )}
  end

  def handle_event("create", %{"call" => params}, socket) do
    Ash.create!(CallLog, %{
      contact_id: params["contact_id"],
      direction: String.to_atom(params["direction"]),
      duration_seconds: String.to_integer(params["duration_seconds"]),
      notes: params["notes"],
      called_at: DateTime.utc_now()
    })

    {:noreply,
     socket
     |> put_flash(:info, "Llamada registrada")
     |> assign(:calls, Ash.read!(CallLog))
     |> assign(:form, to_form(%{"direction" => "outbound", "duration_seconds" => "0"}, as: :call))}
  end

  def render(assigns) do
    ~H"""
    <section class="space-y-6">
      <h1 class="text-xl font-semibold">Llamadas</h1>

      <.simple_form for={@form} id="call-form" phx-submit="create">
        <.input field={@form[:contact_id]} type="select" label="Contacto" options={Enum.map(@contacts, &{"#{&1.first_name} #{&1.last_name}", &1.id})} />
        <.input field={@form[:direction]} type="select" label="Dirección" options={[{"Entrante", "inbound"}, {"Saliente", "outbound"}]} />
        <.input field={@form[:duration_seconds]} type="number" label="Duración (segundos)" />
        <.input field={@form[:notes]} type="textarea" label="Notas" />
        <:actions>
          <.button>Guardar llamada</.button>
        </:actions>
      </.simple_form>

      <ul class="space-y-2">
        <li :for={call <- @calls} class="border rounded p-2">
          {call.direction} · {call.duration_seconds}s · {call.called_at}
          <p>{call.notes}</p>
        </li>
      </ul>
    </section>
    """
  end
end
