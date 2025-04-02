# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SimpleStorageConfigurationCheck < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    s3_setting = Setting.find_by(name: 'storage_provider')
    return if !s3_setting

    add_validations(s3_setting)

    s3_setting.save!(validate: false)
  end

  private

  def add_validations(s3_setting)
    s3_setting.preferences[:validations] = ['Setting::Validation::StorageProvider']

    true
  end
end
