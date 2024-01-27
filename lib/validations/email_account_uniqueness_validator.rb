# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Validations::EmailAccountUniquenessValidator < ActiveModel::Validator
  MATCHED_KEYS = %i[adapter].freeze
  MATCHED_OPTIONS_KEYS = %i[host port user folder].freeze
  MATCHED_AREAS = %w[Email::Account Google::Account Microsoft365::Account].freeze

  def validate(record)
    return if MATCHED_AREAS.exclude?(record.area)

    record_data = extract_matched_data(record)

    return if scope(record).none? { matches?(record_data, _1) }

    record.errors.add :base, __('The provided email account is already in use.')
  end

  private

  def scope(record)
    record
      .class
      .where(area: record.area)
      .then { record.persisted? ? _1.where.not(id: record.id) : _1 }
  end

  def matches?(record_data, other_record)
    other_record_data = extract_matched_data(other_record)

    return false if other_record_data.blank?

    record_data == other_record_data
  end

  def extract_matched_data(record)
    server_data = record.options&.dig(:inbound)

    return if !server_data

    values = server_data.slice(*MATCHED_KEYS)
    options_values = server_data[:options]&.slice(*MATCHED_OPTIONS_KEYS) || {}

    values
      .merge(options_values)
      .transform_values(&:to_s)
  end
end
