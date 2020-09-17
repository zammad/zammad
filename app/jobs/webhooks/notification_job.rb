module Webhooks
  class NotificationJob < ApplicationJob
    def perform(webhook_id:)
      # resource_type: described_class.name.underscore, resource_id: subject.id, webhook_id: webhook.id, event: 'updated'
      webhook = webhook.find(webhook_id)

      resp = Faraday.post(webhook.url,
                          {},
                          default_headers)

    end

    def default_headers
      {
        'Content-Type' => 'application/json'
      }
    end
  end
end
