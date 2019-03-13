class ObjectManager::Attribute::Validation::Date < ObjectManager::Attribute::Validation::Backend

  def validate
    return if value.blank?
    return if irrelevant_attribute?

    validate_past
    validate_future
  end

  private

  def irrelevant_attribute?
    %w[date datetime].exclude?(attribute.data_type)
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
