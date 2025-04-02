# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module TriggerWebhookJob::CustomPayload
  # This module generates the final custom payload by replacing the
  # replacement variables with the actual values.

  extend TriggerWebhookJob::CustomPayload::Parser
  extend TriggerWebhookJob::CustomPayload::Validator

  # The API provides an endpoint GET /api/v1/webhook/replacements returning a
  # list of all available replacement variables lined by this method.
  def self.replacements(pre_defined_webhook_type:)
    hash = {}
    tracks.select(&:root?).each do |track|
      hash.merge!(track.replacements(pre_defined_webhook_type: pre_defined_webhook_type))
    end

    hash
  end

  # This method is called by the webhook job to generate the custom payload.
  def self.generate(record, tracks)
    return {} if record.blank?

    variables = scan(record)
    return JSON.parse(record) if variables.blank?

    tracks.transform_keys!(&:to_sym)
    mappings = parse(variables, tracks)

    # NeverShouldHappen(TM)
    return JSON.parse(record) if mappings.blank?

    replace(record, mappings)

    begin
      valid!(record)
    rescue => e
      return { error: e.message }
    end

    JSON.parse(record)
  end

  # The allowed classes and methods are defined within so called track classes,
  # see files in app/job/trigger_webhook_job/custom_payload/track.
  def self.tracks
    TriggerWebhookJob::CustomPayload::Track.descendants
  end
end
