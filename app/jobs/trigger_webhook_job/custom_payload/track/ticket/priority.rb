# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class TriggerWebhookJob::CustomPayload::Track::Ticket::Priority < TriggerWebhookJob::CustomPayload::Track

  def self.klass
    'Ticket::Priority'
  end
end
