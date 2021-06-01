# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ObjectManager::Attribute::Validation::FuturePast < ObjectManager::Attribute::Validation::Backend

  def validate
    return if value.blank?
    return if irrelevant_attribute?

    validate_past
    validate_future
  end

  private

  def irrelevant_attribute?
    attribute.data_type != 'datetime'.freeze
  end

  def validate_past
    return if attribute.data_option[:past]
    return if !value.past?

    invalid_because_attribute('does not allow past dates.')
  end

  def validate_future
    return if attribute.data_option[:future]
    return if !value.future?

    invalid_because_attribute('does not allow future dates.')
  end
end
