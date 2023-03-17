# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4434GitHubRename < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by name: 'auth_github'

    setting.preferences[:title_i18n][0] = 'GitHub'
    setting.preferences[:description_i18n][0] = 'GitHub'
    setting.save!
  end
end
