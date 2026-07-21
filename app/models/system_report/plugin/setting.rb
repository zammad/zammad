# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class SystemReport::Plugin::Setting < SystemReport::Plugin
  DESCRIPTION = __('Current state of configured settings (excluding passwords and tokens)').freeze

  def fetch
    ::Setting.all.each_with_object([]) do |setting, result|
      next if setting.sensitive?

      result << {
        name:          setting.name,
        current_value: setting.state_current['value'],
        initial_value: setting.state_initial['value'],
      }
    end
  end
end
