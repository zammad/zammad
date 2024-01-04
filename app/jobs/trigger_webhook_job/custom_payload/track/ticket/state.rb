# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class TriggerWebhookJob::CustomPayload::Track::Ticket::State < TriggerWebhookJob::CustomPayload::Track
  def self.klass
    'Ticket::State'
  end
end
