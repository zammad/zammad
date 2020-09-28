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
        ticket.attributes_with_association_names.to_json,
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
  end
end
