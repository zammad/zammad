# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class DropRemovedState < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    state_type = Ticket::StateType.find_by(name: 'removed')
    return if !state_type

    states = state_type.states
    return if states.empty?

    return if Ticket.exists?(state: states)

    states.each(&:delete)
    state_type.delete
  end
end
