# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::CoreWorkflow::Options < FormUpdater::CoreWorkflow::Backend
  def perform
    perform_result[:restrict_values].each do |name, values|
      result[name] ||= {}

      check_clearable(name, values)

      handle_options(name, values)
    end
  end

  private

  def handle_options(name, values)
    if perform_result[:all_options].key?(name)
      set_options(name, values, perform_result[:all_options][name])
    elsif relation_fields.key?(name)
      relation_fields[name][:filter_ids] = values
    end
  end

  def set_options(name, values, all_options)
    options = if all_options.instance_of?(Hash)
                options_hash(values, all_options)
              else
                options_array(values, all_options)
              end

    result[name][:options] = options
  end

  def options_hash(values, all_options)
    values.each_with_object([]) do |value, options|
      next if value.empty?

      options << {
        value: value,
        label: option_hash_label(value, all_options),
      }
    end
  end

  def options_array(values, all_options)
    all_options.each_with_object([]) do |option, options|
      children = []
      if option['children'].present?
        children = options_array(values, option['children'])
      end

      value_exists = values.include?(option['value'])

      next if children.blank? && !value_exists

      options << option_array_resolved(option['name'], option['value'], !value_exists, children)
    end
  end

  def option_array_resolved(label, value, disabled, children)
    resolved_option = {
      value:    value,
      label:    label,
      disabled: disabled,
    }

    if children.any?
      resolved_option[:children] = children
    end

    resolved_option
  end

  def option_hash_label(value, all_options)
    return all_options[value] if all_options[value].present?

    if %w[false true].include?(value)
      return all_options[ActiveModel::Type::Boolean.new.cast(value)]
    end

    nil
  end

  def check_clearable(name, values)
    result[name][:clearable] = values.include?('')
  end
end
