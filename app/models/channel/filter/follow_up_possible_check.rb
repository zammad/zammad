# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::FollowUpPossibleCheck

  def self.run(_channel, mail)
    ticket_id = mail['x-zammad-ticket-id'.to_sym]
    return true if !ticket_id

    ticket = Ticket.lookup(id: ticket_id)
    return true if !ticket
    return true if !ticket.state.state_type.name.match?(/^(closed|merged|removed)/i)

    # in case of closed tickets, remove follow-up information
    case ticket.group.follow_up_possible
    when 'new_ticket'
      mail[:subject]                        = ticket.subject_clean(mail[:subject])
      mail['x-zammad-ticket-id'.to_sym]     = nil
      mail['x-zammad-ticket-number'.to_sym] = nil
    end

    true
  end
end
