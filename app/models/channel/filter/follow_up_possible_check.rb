# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::FollowUpPossibleCheck

  def self.run(_channel, mail, _transaction_params)
    ticket_id = mail[:'x-zammad-ticket-id']
    return true if !ticket_id

    ticket = Ticket.lookup(id: ticket_id)
    return true if !ticket
    return true if !ticket.state.state_type.name.match?(%r{^(closed|merged|removed)}i)

    # in case of closed tickets, remove follow-up information
    case ticket.group.follow_up_possible
    when 'new_ticket'
      mail[:subject] = ticket.subject_clean(mail[:subject])
      mail[:'x-zammad-ticket-id']     = nil
      mail[:'x-zammad-ticket-number'] = nil
    end

    true
  end
end
