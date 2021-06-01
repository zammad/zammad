# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ObjectManager::Attribute::Validation::MinMax < ObjectManager::Attribute::Validation::Backend

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

    invalid_because_attribute("is smaller than the allowed minimum value of #{attribute.data_option[:min]}")
  end

  def validate_max
    return if !attribute.data_option[:max]
    return if value <= attribute.data_option[:max]

    invalid_because_attribute("is larger than the allowed maximum value of #{attribute.data_option[:max]}")
  end
end
