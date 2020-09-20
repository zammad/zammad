module Webhooks
  class NotificationFailed < StandardError; end

  class NotificationJob < ApplicationJob

    retry_on NotificationFailed, attempts: 5, wait: lambda { |executions|
      executions * 10.seconds
    }

    def perform(payload)
      webhook = Webhook.find(payload.fetch(:webhook_id))

      response = Faraday.post(
        webhook.url,
        payload.to_json,
        default_headers
      )

      raise NotificationFailed if !response.success?
    end

    private

    def default_headers
      {
        'Content-Type' => 'application/json',
        'User-Agent'   => "Zammad/#{Version.get}"
      }
    end
  end
end
