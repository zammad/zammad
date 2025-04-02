# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TriggerWebhookJob::CustomPayload::Track::Ticket::Article::Type < TriggerWebhookJob::CustomPayload::Track
  def self.klass
    'Ticket::Article::Type'
  end
end
