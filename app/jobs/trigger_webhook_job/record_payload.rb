class TriggerWebhookJob::RecordPayload

  def self.generate(record)
    return {} if record.blank?

    backend   = "TriggerWebhookJob::RecordPayload::#{record.class.name}".constantize
    generator = backend.new(record)
    generator.generate
  end
end
