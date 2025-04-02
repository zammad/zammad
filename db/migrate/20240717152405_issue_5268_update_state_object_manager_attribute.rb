# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Issue5268UpdateStateObjectManagerAttribute < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Ticket::State.update_state_field_configuration
  end
end
