defmodule ContactosApp.Workers.SendWhatsappWorker do
  use Oban.Worker, queue: :messages

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"message_log_id" => _id}}) do
    # Integrar WhatsApp Cloud API / Twilio aquí
    :ok
  end
end
