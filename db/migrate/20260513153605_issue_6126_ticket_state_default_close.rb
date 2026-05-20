# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue6126TicketStateDefaultClose < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_default_close_column
    set_default_close_state
  end

  def add_default_close_column
    add_column :ticket_states, :default_close, :boolean, null: false, default: false
    add_index  :ticket_states, :default_close

    Ticket::State.reset_column_information
  end

  def set_default_close_state
    ticket_state_closed = Ticket::State.find_by(name: 'closed')

    if !ticket_state_closed
      state_type_closed = Ticket::StateType.find_by(name: 'closed')

      if !state_type_closed
        state_type_closed = Ticket::StateType.first
      end

      ticket_state_closed = Ticket::State.find_by(state_type: state_type_closed) || Ticket::State.first
    end

    return if !ticket_state_closed

    ticket_state_closed.default_close = true
    ticket_state_closed.save!
  end
end
