# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class VectorDBSettingValidation < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(name: 'vectordb_enabled')
    return if setting.nil?

    setting.preferences = setting.preferences.merge(validations: ['Setting::Validation::VectorDB'])

    # An existing installation may have the setting enabled with a setup the new validation
    # rejects; that must not abort the upgrade.
    setting.skip_validate = true
    setting.save!
  end
end
