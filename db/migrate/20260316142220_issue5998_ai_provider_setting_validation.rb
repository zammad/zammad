# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue5998AIProviderSettingValidation < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(name: 'ai_provider')
    return if setting.nil?

    setting.update!(preferences: setting.preferences.merge(validations: ['Setting::Validation::AIProvider']))
  end
end
