# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Validations::ObjectManager::AttributeValidator::Option < Validations::ObjectManager::AttributeValidator::Backend

  def validate
    return if value.blank?
    return if !attribute.option_attribute?
    return if ApplicationHandleInfo.current != 'ai_agent_execution'

    case attribute.data_type
    when 'select', 'tree_select'
      validate_single_option
    when 'multiselect', 'multi_tree_select'
      validate_multiple_options
    end
  end

  private

  def validate_single_option
    return if option_valid?(value)

    invalid_because_attribute(__('contains invalid option: %{option}'), option: value)
  end

  def validate_multiple_options
    return if value.blank?
    return if !value.is_a?(Array)

    value.each do |item|
      next if option_valid?(item)

      invalid_because_attribute(__('contains invalid option: %{option}'), option: item)
    end
  end

  def option_valid?(option_value)
    options = available_options
    return false if options.blank?

    options.key?(option_value.to_s)
  end

  def available_options
    @available_options ||= attribute.data_option[:historical_options]
  end
end
