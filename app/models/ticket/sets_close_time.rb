# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# Adds close time (if missing) when tickets are closed.
module Ticket::SetsCloseTime
  extend ActiveSupport::Concern

  included do
    before_create  :ticket_set_close_time
    before_update  :ticket_set_close_time
  end

  private

  def ticket_set_close_time

    # return if we run import mode
    return true if Setting.get('import_mode')

    # check if ticket is closed now
    return true if !ticket_closed?(self)

    # set last close_at
    if changes_to_save['state_id'].present? || last_close_at.blank?
      self.last_close_at = Time.zone.now
    end

    # check if close_at is already set
    return true if close_at

    # set close_at
    self.close_at = Time.zone.now
  end

  def ticket_closed?(ticket)
    return false if !ticket.state_id

    state = Ticket::State.lookup(id: ticket.state_id)
    state_type = Ticket::StateType.lookup(id: state.state_type_id)
    return true if state_type.name == 'closed'

    false
  end

end
