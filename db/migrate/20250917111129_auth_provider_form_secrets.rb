# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AuthProviderFormSecrets < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    migrate_auth_provider_settings(
      'auth_twitter_credentials'             => 'secret',
      'auth_facebook_credentials'            => 'app_secret',
      'auth_google_oauth2_credentials'       => 'client_secret',
      'auth_linkedin_credentials'            => 'app_secret',
      'auth_github_credentials'              => 'app_secret',
      'auth_gitlab_credentials'              => 'app_secret',
      'auth_microsoft_office365_credentials' => 'app_secret',
      'auth_weibo_credentials'               => 'client_secret',
    )
  end

  private

  def migrate_auth_provider_settings(setting_field_map)
    setting_field_map.each do |setting_name, field_name|
      setting = Setting.find_by(name: setting_name)
      next if !setting

      field = setting.options[:form]&.find { |field| field[:name] == field_name }
      next if !field

      field[:input_type] = 'password'

      setting.save!
    end
  end
end
