module Webhooks
  class NotificationFailed < StandardError; end

  class NotificationJob < ApplicationJob

    retry_on NotificationFailed, attempts: 5, wait: lambda { |executions|
      executions * 10.seconds
    }

    def perform(params)
      trigger = Trigger.find(params.fetch(:trigger_id))
      webhook = trigger.perform['notification.webhook']

      response = Faraday.post(
        webhook['endpoint'],
        payload(params.fetch(:ticket_id)),
        headers(trigger, webhook, params.fetch(:delivery_id))
      )

      raise NotificationFailed if !response.success?
    end

    private

    def headers(trigger, webhook, delivery_id)
      {
        'Content-Type'      => 'application/json',
        'User-Agent'        => "Zammad/#{Version.get}",
        'X-Zammad-Trigger'  => trigger.name,
        'X-Zammad-Delivery' => delivery_id
      }.merge(signature(webhook))
    end

    def signature(webhook)
      if webhook['token'].present?
        {
          'X-Hub-Signature' => OpenSSL::HMAC.hexdigest('sha1', webhook['token'], 'verified')
        }
      else
        {}
      end
    end

    def payload(ticket_id)
      ticket = Ticket.lookup(id: ticket_id)
      ticket.attributes_with_association_names.to_json
    end
  end
end
