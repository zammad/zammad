# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue3245Office365MicrosoftRename < ActiveRecord::Migration[6.0]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by name: 'auth_microsoft_office365'

    setting.preferences[:title_i18n][0] = 'Microsoft'
    setting.preferences[:description_i18n][0] = 'Microsoft'
    setting.save!
  rescue => e
    Rails.logger.error e
  end
end
