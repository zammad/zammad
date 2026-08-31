# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::ApplyValue::FormId < FormUpdater::ApplyValue::Base

  def can_handle_field?(field:, field_attribute:)
    field == 'form_id'
  end

  def map_value(field:, config:)
    attachments = UploadCache.new(config['value'])
      .attachments
      .reject(&:inline?)
      .map do |attachment|
        {
          id:   Gql::ZammadSchema.id_from_object(attachment),
          name: attachment.filename,
          size: attachment.size,
          type: attachment.preferences['Content-Type'],
        }
      end

    result['attachments'] ||= {}
    result['attachments'][value_key(config)] = attachments
  end

  private

  # A plain `value` sets the field without giving it a baseline: the form captures a field's `_init`
  #   synchronously when the node is created, and nothing backfills it from a later round trip. So a
  #   cache seeded *from the record* has to arrive as `initialValue`, or the file field reads as
  #   changed before anybody touched it - and every "is this dirty" decision built on it is wrong.
  #
  # Opt-in per caller rather than always, because the other seeds are not baselines: a template, a
  #   shared draft and a split article all pull in content the user then has to be able to save, so
  #   those must stay `value` and leave the form dirty.
  def value_key(config)
    config['as_initial'] ? :initialValue : :value
  end
end
