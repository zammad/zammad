# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class MaintenanceAssociationsCleanup < ActiveRecord::Migration[5.2]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    remove_reference :templates, :user, index: true, foreign_key: true
    remove_reference :text_modules, :user, index: true, foreign_key: true
  end
end
