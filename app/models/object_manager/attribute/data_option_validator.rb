# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class ObjectManager::Attribute::DataOptionValidator < ActiveModel::Validator
  VALIDATE_INTEGER_MIN    = -2_147_483_647
  VALIDATE_INTEGER_MAX    = 2_147_483_647
  VALIDATE_UNSIGNED_INTEGER_REGEXP = %r{^\d+$}
  INPUT_DATA_TYPES = %w[text password tel fax email url].freeze

  def validate(record)
    case record.data_type
    when 'input'
      type_check(record)
      maxlength_check(record)
    when %r{^(textarea|richtext)$}
      maxlength_check(record)
    when 'integer'
      min_max_check(record)
    when %r{^((multi_)?tree_select|(multi)?select|checkbox)$}
      default_check(record)
      relation_check(record)
    when 'boolean'
      default_check(record)
      presence_check(record)
    when 'datetime'
      future_check(record)
      past_check(record)
    end
  end

  private

  def maxlength_check(record)
    return if VALIDATE_UNSIGNED_INTEGER_REGEXP.match?(record.local_data_option[:maxlength].to_s)

    record.errors.add :base, __('Max length must be an integer.')
  end

  def type_check(record)
    return if INPUT_DATA_TYPES.include? record.local_data_option[:type]

    record.errors.add :base, __('Input field must be text, password, tel, fax, email or url type.')
  end

  def default_check(record)
    return if record.local_data_option.key?(:default)

    record.errors.add :base, __('Default value is required.')
  end

  def relation_check(record)
    return if !record.local_data_option[:options].nil? || !record.local_data_option[:relation].nil?

    record.errors.add :base, __('Options or relation is required.')
  end

  def presence_check(record)
    return if !record.local_data_option[:options].nil?

    record.errors.add :base, __('Options are required.')
  end

  def future_check(record)
    return if !record.local_data_option[:future].nil?

    record.errors.add :base, __('Allow future dates toggle value is required.')
  end

  def past_check(record)
    return if !record.local_data_option[:past].nil?

    record.errors.add :base, __('Allow past dates toggle value is required.')
  end

  def min_max_check(record)
    min_ok = min_max_validate_min(record)
    max_ok = min_max_validate_max(record)

    return if !min_ok || !max_ok

    min_max_validate_range(record)
  end

  def min_max_validate_min(record)
    min = record.local_data_option[:min]

    if !min.is_a?(Integer)
      record.errors.add :base, __('Minimal value must be an integer')

      return
    end

    if min < VALIDATE_INTEGER_MIN
      record.errors.add :base, __('Minimal value must be higher than -2147483648')
      return
    end

    if min > VALIDATE_INTEGER_MAX
      record.errors.add :base, __('Minimal value must be lower than 2147483648')
      return
    end

    true
  end

  def min_max_validate_max(record)
    max = record.local_data_option[:max]

    if !max.is_a?(Integer)
      record.errors.add :base, __('Maximal value must be an integer')
      return
    end

    if max < VALIDATE_INTEGER_MIN
      record.errors.add :base, __('Maximal value must be higher than -2147483648')
      return
    end

    if max > VALIDATE_INTEGER_MAX
      record.errors.add :base, __('Maximal value must be lower than 2147483648')
      return
    end

    true
  end

  def min_max_validate_range(record)
    min = record.local_data_option[:min]
    max = record.local_data_option[:max]

    return if min.is_a?(Integer) && max.is_a?(Integer) && min <= max

    record.errors.add :base, __('Maximal value must be higher than or equal to minimal value')
  end
end
