# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue6185TextModulePermissionLabel < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Permission.find_by(name: 'admin.text_module')&.update!(label: 'Text Modules')
  end
end
