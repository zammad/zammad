# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue5556TimeAccountingPrio < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    CoreWorkflow.find_by(name: 'base - ticket time accouting check').update!(priority: 0, name: 'base - ticket time accounting check')
  end
end
