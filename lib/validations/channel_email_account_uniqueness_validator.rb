# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Validations::ChannelEmailAccountUniquenessValidator < ActiveModel::Validator
  MATCHED_KEYS = %i[adapter].freeze
  MATCHED_OPTIONS_KEYS = %i[host port user folder].freeze
  MATCHED_AREAS = %w[Email::Account Google::Account Microsoft365::Account].freeze

  def validate(record)
    return if MATCHED_AREAS.exclude?(record.area)
    return if !matching_changes?(record)

    record_data = extract_matched_data(record.options)

    return if scope(record).none? { matches?(record_data, _1) }

    record.errors.add :base, __('The provided email account is already in use.')
  end

  private

  # https://github.com/zammad/zammad/issues/5111
  # Some systems may have duplicate channels created before this validation was added
  # Checking uniqueness on any update blocks XOAuth2 token update on such channels
  def matching_changes?(record)
    extract_matched_data(record.options) != extract_matched_data(record.options_was)
  end

  def scope(record)
    record
      .class
      .where(area: record.area)
      .then { record.persisted? ? _1.where.not(id: record.id) : _1 }
  end

  def matches?(record_data, other_record)
    other_record_data = extract_matched_data(other_record.options)

    return false if other_record_data.blank?

    record_data == other_record_data
  end

  def extract_matched_data(options)
    server_data = options&.dig(:inbound)

    return if !server_data

    values = server_data.slice(*MATCHED_KEYS)
    options_values = server_data[:options]&.slice(*MATCHED_OPTIONS_KEYS) || {}

    values
      .merge(options_values)
      .transform_values(&:to_s)
  end
end
