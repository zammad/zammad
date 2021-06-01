# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TriggerWebhookJob::RecordPayload

  def self.generate(record)
    return {} if record.blank?

    backend   = "TriggerWebhookJob::RecordPayload::#{record.class.name}".constantize
    generator = backend.new(record)
    generator.generate
  end
end
