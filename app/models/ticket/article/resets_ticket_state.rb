# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# Reopens the ticket in case certain new articles are created.
module Ticket::Article::ResetsTicketState
  extend ActiveSupport::Concern

  included do
    after_create :ticket_article_reset_ticket_state
  end

  private

  def ticket_article_reset_ticket_state

    # return if we run import mode
    return true if Setting.get('import_mode')

    # only change state if not processed via postmaster
    return true if ApplicationHandleInfo.postmaster?

    # if article in internal
    return true if internal

    # if sender is agent
    return true if Ticket::Article::Sender.lookup(id: sender_id).name != 'Agent'

    # if article is a message to customer
    return true if !Ticket::Article::Type.lookup(id: type_id).communication

    # if current ticket state is still new
    ticket = Ticket.find_by(id: ticket_id)
    return true if !ticket

    new_state = Ticket::State.find_by(default_create: true)
    return true if ticket.state_id != new_state.id

    state = Ticket::State.find_by(default_follow_up: true)
    return true if !state

    # set ticket to open
    ticket.state_id = state.id

    # save ticket
    ticket.save
  end
end
