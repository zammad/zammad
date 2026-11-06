# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

  # The options Core Workflow allows, as the field layer lists them. A value it allows that the list lacks — an option
  #   the admin removed, or one set over the API — stays on the field, so the form keeps it as it is.
  def set_options(name, values, all_options, historical_options)
    options = field_types[name]&.option_list(allowed: values)
    return if options.nil?

    tree    = all_options.is_a?(Array)
    options = options.sort_by { |option| values.index(option.value) } if !tree
    result[name][:options] = FormUpdater::OptionList.form_options(options, tree:)

    keep_unlisted_values(name, values, options, historical_options.to_h.stringify_keys, tree:)
  end

  def keep_unlisted_values(name, values, options, historical_options, tree:)
    # A tree has always kept the field's value, listed or not.
    return uncheck_reject_non_existent_values(name) if tree && values.any?

    listed = Service::EntityAttribute::Option.flatten(options).map(&:value)

    values.each do |value|
      next if value.empty? || listed.include?(value)

      uncheck_reject_non_existent_values(name) if historical_options[value].present? || object_current_value?(name, value)
    end
  end

  def object_current_value?(name, value)
    @object.present? && Array(@object[name]).include?(value)
  end

  def check_clearable(name, values)
    result[name][:clearable] = values.include?('')
  end

  def uncheck_reject_non_existent_values(name)
    return if !result[name][:rejectNonExistentValues]

    result[name][:rejectNonExistentValues] = false
  end
end
