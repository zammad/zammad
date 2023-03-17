# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue3627OutdatedUrlsSecurityPage < ActiveRecord::Migration[6.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by name: 'auth_google_oauth2'
    setting.preferences[:description_i18n][2] = 'https://console.cloud.google.com/apis/credentials'
    setting.save!

    setting = Setting.find_by name: 'auth_microsoft_office365'
    setting.preferences[:description_i18n][2] = 'https://portal.azure.com'
    setting.save!
  end
end
