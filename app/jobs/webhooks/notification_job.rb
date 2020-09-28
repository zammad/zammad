module Webhooks
  class NotificationFailed < StandardError; end

  class NotificationJob < ApplicationJob

    retry_on NotificationFailed, attempts: 5, wait: lambda { |executions|
      executions * 10.seconds
    }

    def perform(ticket_id:, trigger_id:, delivery_id:)
      ticket = Ticket.lookup(id: ticket_id)
      trigger = Trigger.find(trigger_id)
      webhook = trigger.perform['notification.webhook']

      response = Faraday.post(
        webhook['endpoint'],
        build_payload(ticket),
        {
          'Content-Type'      => 'application/json',
          'User-Agent'        => "Zammad/#{Version.get}",
          'X-Zammad-Trigger'  => trigger.name,
          'X-Zammad-Delivery' => delivery_id
        }.merge(signature(webhook))
      )

      raise NotificationFailed if !response.success?
    end

    private

    def signature(webhook)
      if webhook['token'].present?
        {
          'X-Hub-Signature' => OpenSSL::HMAC.hexdigest('sha1', webhook['token'], 'verified')
        }
      else
        {}
      end
    end

    def build_payload(ticket)
      ticket.as_json(include: [
                       :group,
                       :organization,
                       { articles: { include: [
                         { created_by: { include: %i[organization organizations roles] } },
                         { updated_by: { include: %i[organization organizations roles] } },
                         { origin_by: { include: %i[organization organizations roles] } },
                         { sender: { include: %i[organization organizations roles] } }
                       ] } },
                       :ticket_time_accounting,
                       :flags,
                       :state,
                       :priority,
                       { customer: { include: %i[organization organizations roles] } },
                       { created_by: { include: %i[organization organizations roles] } },
                       { updated_by: { include: %i[organization organizations roles] } }
                     ])
    end
  end
end
