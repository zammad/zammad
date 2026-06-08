# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AuthProviderFormSecrets, type: :db_migration do
  before do
    revert_auth_provider_settings(
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

  it 'migrates all auth provider form settings' do
    expect { migrate }
      .to change { setting_field_input_type('auth_twitter_credentials', 'secret') }.from(nil).to('password')
      .and change { setting_field_input_type('auth_facebook_credentials', 'app_secret') }.from(nil).to('password')
      .and change { setting_field_input_type('auth_google_oauth2_credentials', 'client_secret') }.from(nil).to('password')
      .and change { setting_field_input_type('auth_linkedin_credentials', 'app_secret') }.from(nil).to('password')
      .and change { setting_field_input_type('auth_github_credentials', 'app_secret') }.from(nil).to('password')
      .and change { setting_field_input_type('auth_gitlab_credentials', 'app_secret') }.from(nil).to('password')
      .and change { setting_field_input_type('auth_microsoft_office365_credentials', 'app_secret') }.from(nil).to('password')
      .and change { setting_field_input_type('auth_weibo_credentials', 'client_secret') }.from(nil).to('password')
  end

  def revert_auth_provider_settings(setting_field_map)
    setting_field_map.each do |setting_name, field_name|
      setting = Setting.find_by(name: setting_name)
      field = setting.options[:form]&.find { |field| field[:name] == field_name }
      field.delete(:input_type)
      setting.save!
    end
  end

  def setting_field_input_type(setting_name, field_name)
    Setting.find_by(name: setting_name).options[:form].find { |field| field[:name] == field_name }[:input_type]
  end
end
