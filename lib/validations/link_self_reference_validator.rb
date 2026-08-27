# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Validations::LinkSelfReferenceValidator < ActiveModel::Validator
  ERROR_MESSAGE = __('An object cannot be linked to itself.')

  def validate(record)
    return if record.link_object_source_id != record.link_object_target_id
    return if record.link_object_source_value != record.link_object_target_value

    record.errors.add :base, ERROR_MESSAGE
  end
end
