# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Validations::ObjectManager::AttributeValidator::MaxLength < Validations::ObjectManager::AttributeValidator::Backend

  def validate
    return if value.blank?
    return if irrelevant_attribute?

    validate_max_length
  end

  private

  def irrelevant_attribute?
    %w[input textarea].exclude? attribute.data_type
  end

  def maxlength
    attribute.data_option[:maxlength]
  end

  def validate_max_length
    return if value.length <= maxlength

    invalid_because_attribute(__('is longer than the allowed length %{maxlength}'), maxlength: maxlength)
  end
end
