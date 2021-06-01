# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TriggerWebhookJob::RecordPayload::Ticket::Article < TriggerWebhookJob::RecordPayload::Base

  ASSOCIATIONS = %i[created_by updated_by].freeze

  def generate
    result = add_attachments_url(super)
    add_accounted_time(result)
  end

  def add_accounted_time(result)
    result['accounted_time'] = record.ticket_time_accounting&.time_unit.to_i
    result
  end

  def add_attachments_url(result)
    return result if result['attachments'].blank?

    result['attachments'].each do |attachment|
      attachment['url'] = format(attachment_url_template, result['ticket_id'], result['id'], attachment['id'])
    end

    result
  end

  def attachment_url_template
    @attachment_url_template ||= "#{Setting.get('http_type')}://#{Setting.get('fqdn')}#{Rails.configuration.api_path}/ticket_attachment/%s/%s/%s"
  end
end
