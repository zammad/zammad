# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::CoreWorkflow::Options < FormUpdater::CoreWorkflow::Backend
  def perform
    perform_result[:restrict_values].each do |name, values|
      result[name] ||= {}
      result[name][:rejectNonExistentValues] = true

      check_clearable(name, values)

      handle_options(name, values)
    end
  end

  private

  def handle_options(name, values)
    if perform_result[:all_options].key?(name)
      set_options(name, values, perform_result[:all_options][name], perform_result[:historical_options][name])
    elsif relation_fields.key?(name)
      relation_fields[name][:filter_ids] = values
    end
  end

  def set_options(name, values, all_options, historical_options)
    # Currently we implemented a special handling for the historical options, because we need to detect if we have
    # one option inside the given options from core workflow, so that the frontend can add this option for
    # the current value from the field.
    # This happens when the value from the field is no longer present in the current configured options from the
    # object manager attribute.
    options = if all_options.instance_of?(Hash)
                options_hash(name, values, all_options, historical_options)
              else
                # Remember which option values are touched inside the recursive options build function, so that
                #  we can check if we have a untouched option inside the option values.
                # Then we need to add the historical options inside the frontend field to the options.
                touched_values_count = 0

                result_options_array = options_array(values, all_options, historical_options, touched_values_count)

                if touched_values_count < values.length
                  uncheck_reject_non_existent_values(name)
                end

                result_options_array
              end

    result[name][:options] = options
  end

  def options_hash(name, values, all_options, historical_options)
    values.each_with_object([]) do |value, options|
      next if value.empty?

      label = option_hash_label(name, value, all_options, historical_options)

      next if label.blank?

      options << {
        value: value,
        label: label,
      }
    end
  end

  def options_array(values, all_options, historical_options, touched_values_count)
    all_options.each_with_object([]) do |option, options|
      children = []
      if option['children'].present?
        children = options_array(values, option['children'], historical_options, touched_values_count)
      end

      value_exists = values.include?(option['value'])

      next if children.blank? && !value_exists

      touched_values_count += 1

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

  def option_hash_label(name, value, all_options, historical_options)
    return all_options[value] if all_options[value].present?

    # Special handling for boolean fields.
    if %w[false true].include?(value)
      return all_options[ActiveModel::Type::Boolean.new.cast(value)]
    end

    # When the not existing option is inside the historical options we need to add the
    # option inside the frontend field.
    if historical_options[value].present?
      uncheck_reject_non_existent_values(name)
    end

    nil
  end

  def check_clearable(name, values)
    result[name][:clearable] = values.include?('')
  end

  def uncheck_reject_non_existent_values(name)
    return if !result[name][:rejectNonExistentValues]

    result[name][:rejectNonExistentValues] = false
  end
end
