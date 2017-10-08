# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::ResetNewState < ActiveRecord::Observer
  observe 'ticket::_article'

  def after_create(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    # only change state if not processed via postmaster
    return if ApplicationHandleInfo.current.split('.')[1] == 'postmaster'

    # if article in internal
    return true if record.internal

    # if sender is agent
    return true if Ticket::Article::Sender.lookup(id: record.sender_id).name != 'Agent'

    # if article is a message to customer
    return true if !Ticket::Article::Type.lookup(id: record.type_id).communication

    # if current ticket state is still new
    ticket = Ticket.lookup(id: record.ticket_id)
    new_state = Ticket::State.find_by(default_create: true)
    return true if ticket.state_id != new_state.id

    state = Ticket::State.find_by(default_follow_up: true)
    return if !state

    # set ticket to open
    ticket.state_id = state.id

    # save ticket
    ticket.save
  end
end
