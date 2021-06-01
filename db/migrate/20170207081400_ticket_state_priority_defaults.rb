# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TicketStatePriorityDefaults < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_column :ticket_states, :default_create, :boolean, null: false, default: false
    add_index  :ticket_states, :default_create
    add_column :ticket_states, :default_follow_up, :boolean, null: false, default: false
    add_index  :ticket_states, :default_follow_up

    add_column :ticket_priorities, :default_create, :boolean, null: false, default: false
    add_index  :ticket_priorities, :default_create

    # Set defaults
    ticket_state_new = Ticket::State.find_by(name: 'new')
    if !ticket_state_new
      ticket_state_new = Ticket::State.first
    end
    if ticket_state_new
      ticket_state_new.default_create = true
      ticket_state_new.save!
    end

    ticket_state_open = Ticket::State.find_by(name: 'open')
    if !ticket_state_open
      ticket_state_open = Ticket::State.first
    end
    if ticket_state_open
      ticket_state_open.default_follow_up = true
      ticket_state_open.save!
    end

    ticket_priority = Ticket::Priority.find_by(name: '2 normal')
    if !ticket_priority
      ticket_priority = Ticket::Priority.first
    end
    if ticket_priority
      ticket_priority.default_create = true
      ticket_priority.save!
    end

    Cache.clear
  end

  def down
    remove_index  :ticket_states, :default_create
    remove_column :ticket_states, :default_create, :boolean
    remove_index  :ticket_states, :default_follow_up
    remove_column :ticket_states, :default_follow_up, :boolean

    remove_index  :ticket_priorities, :default_create
    remove_column :ticket_priorities, :default_create, :boolean

    Cache.clear
  end
end
