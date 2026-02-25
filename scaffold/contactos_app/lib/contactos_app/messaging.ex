defmodule ContactosApp.Messaging do
  alias ContactosApp.CRM.MessageLog
  alias ContactosApp.Workers.{SendEmailWorker, SendWhatsappWorker}

  def queue_message(attrs) do
    log = Ash.create!(MessageLog, attrs)

    worker = if log.channel == :email, do: SendEmailWorker, else: SendWhatsappWorker

    %{message_log_id: log.id}
    |> worker.new(queue: :messages)
    |> Oban.insert!()

    {:ok, log}
  end
end
