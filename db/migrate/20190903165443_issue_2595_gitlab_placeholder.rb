# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue2595GitLabPlaceholder < ActiveRecord::Migration[5.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(name: 'auth_gitlab_credentials')
    setting.options['form'].last['placeholder'] = 'https://gitlab.YOURDOMAIN.com/api/v4/'
    setting.save!
  end
end
