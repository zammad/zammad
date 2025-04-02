# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SystemReport::Plugin::Setting < SystemReport::Plugin
  SENSITIVE_SETTING_NAMES = %w[secret auth_ password pw credential endpoint_key _config _token recovery_codes pwd].freeze

  DESCRIPTION = __('Current state of configured settings (excluding passwords and tokens)').freeze

  def fetch
    ::Setting.all.each_with_object([]) do |setting, result|
      next if SENSITIVE_SETTING_NAMES.any? { |word| setting.name.include?(word) }

      result << {
        name:          setting.name,
        current_value: setting.state_current['value'],
        initial_value: setting.state_initial['value'],
      }
    end
  end
end
