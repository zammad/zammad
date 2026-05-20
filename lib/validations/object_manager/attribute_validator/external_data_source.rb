# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Validations::ObjectManager::AttributeValidator::ExternalDataSource < Validations::ObjectManager::AttributeValidator::Backend

  ALLOWED_KEYS         = %w[label value].sort.freeze
  ALLOWED_VALUE_TYPES  = [String, Numeric, TrueClass, FalseClass, NilClass].freeze

  def validate
    return if attribute.data_type != 'autocompletion_ajax_external_data_source'
    return if value.nil? || value == {}

    if !value.is_a?(Hash) || value.keys.map(&:to_s).sort != ALLOWED_KEYS
      invalid_because_attribute(__('must be a hash with "label" and "value" keys'))
      return
    end

    return if value.each_value.all? { |item| ALLOWED_VALUE_TYPES.any? { |type| item.is_a?(type) } }

    invalid_because_attribute(__('contains an invalid "label" or "value" entry'))
  end
end
