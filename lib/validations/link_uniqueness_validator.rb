# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Validations::LinkUniquenessValidator < ActiveModel::Validator
  ATTRIBUTES = %i[
    link_object_source_id link_object_source_value
    link_object_target_id link_object_target_value
    link_type_id
  ].freeze
  ERROR_MESSAGE = __('Link already exists')

  def validate(record)
    return if !scope(record).exists?

    record.errors.add :base, ERROR_MESSAGE
  end

  private

  def scope(record)
    record
      .class
      .where(record.slice(ATTRIBUTES))
      .then { record.persisted? ? _1.where.not(id: record.id) : _1 }
  end
end
