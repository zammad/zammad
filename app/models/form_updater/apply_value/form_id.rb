# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::ApplyValue::FormId < FormUpdater::ApplyValue::Base

  def can_handle_field?(field:, field_attribute:)
    field == 'form_id'
  end

  def map_value(field:, config:)
    attachments = []

    UploadCache.new(config['value'])
      .attachments
      .reject(&:inline?)
      .map do |attachment|
      attachments << {
        id:   Gql::ZammadSchema.id_from_object(attachment),
        name: attachment.filename,
        size: attachment.size,
        type: attachment.preferences['Content-Type'],
      }
    end

    result['attachments'] ||= {}
    result['attachments'][:value] = attachments
  end
end
