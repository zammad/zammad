# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class PasswordSettingsChangeType < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    migrate_settings_auth_openid_connect_credentials_pkce

    %w[password_min_2_lower_2_upper_characters password_need_digit password_need_special_character].each do
      migrate_password_setting(it)
    end
  end

  private

  def migrate_settings_auth_openid_connect_credentials_pkce
    setting = Setting.find_by(name: 'auth_openid_connect_credentials')
    setting.options['form'].find { it['name'] == 'pkce' }['tag'] = 'boolean'
    setting.save!
  end

  def migrate_password_setting(name)
    setting = Setting.find_by(name:)
    setting.state_initial['value'] = ActiveModel::Type::Boolean.new.cast(setting.state_initial['value'])
    setting.state_current['value'] = ActiveModel::Type::Boolean.new.cast(setting.state_current['value'])

    form_elem = setting.options['form'].find { it['name'] == name }
    form_elem['tag']     = 'boolean'
    form_elem['display'] = ''
    form_elem['options'] = {
      true  => 'yes',
      false => 'no',
    }

    setting.save!
  end
end
