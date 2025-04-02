# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Validations::ObjectManager::AttributeValidator::MinMax < Validations::ObjectManager::AttributeValidator::Backend

  def validate
    return if value.blank?
    return if irrelevant_attribute?

    validate_min
    validate_max
  end

  private

  def irrelevant_attribute?
    attribute.data_type != 'integer'.freeze
  end

  def validate_min
    return if !attribute.data_option[:min]
    return if value >= attribute.data_option[:min]

    invalid_because_attribute(__('is smaller than the allowed minimum value of %{min_value}'), min_value: attribute.data_option[:min])
  end

  def validate_max
    return if !attribute.data_option[:max]
    return if value <= attribute.data_option[:max]

    invalid_because_attribute(__('is larger than the allowed maximum value of %{max_value}'), max_value: attribute.data_option[:max])
  end
end
