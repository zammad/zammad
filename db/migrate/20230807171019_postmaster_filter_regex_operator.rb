# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class PostmasterFilterRegexOperator < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    update_postmaster_filter
    update_monitoring_settings
  end

  private

  OPERATOR_MAPPING = {
    'contains'     => 'matches regex',
    'contains not' => 'does not match regex',
  }.freeze

  def update_postmaster_filter
    PostmasterFilter.in_batches.each_record do |filter|
      next if filter.match.blank?

      filter.match.each_value do |condition|
        next if !relevant_filter_condition?(condition)

        regex = condition_regex_value(condition[:value])
        next if regex.blank?

        update_condition(condition, regex)
      end

      filter.save!
    end
  end

  def update_monitoring_settings
    %w[nagios icinga monit].each do |monitoring_name|
      setting_name = "#{monitoring_name}_sender"
      value = Setting.get(setting_name)

      regex = condition_regex_value(value)
      next if regex.blank?

      Setting.set(setting_name, regex)
    end
  end

  def relevant_filter_condition?(condition)
    return false if condition[:operator].blank?
    return false if OPERATOR_MAPPING.keys.exclude?(condition[:operator])

    true
  end

  def condition_regex_value(value)
    match = %r{^regex:(?<value>.+?)$}.match(value)
    return if match.blank?

    match[:value]
  end

  def update_condition(condition, regex)
    condition[:operator] = OPERATOR_MAPPING[condition[:operator]]
    condition[:value] = regex
  end
end
