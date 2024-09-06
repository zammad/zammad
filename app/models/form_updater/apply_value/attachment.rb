# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::ApplyValue::Attachment < FormUpdater::ApplyValue::Base

  def can_handle_field?(field:, field_attribute:)
    field == 'attachments'
  end

  def map_value(field:, config:)
    return if config['value'].nil? || !config['value'].is_a?(Array)

    result['attachments'][:value] = Array(config['value']).map do |elem|
      resolve_attachment(elem)
    end
  end

  private

  def resolve_attachment(attachment)
    {
      id:   attachment.id,
      name: attachment.filename,
      size: attachment.size,
      type: attachment.preferences['Content-Type'],
    }
  end
end
