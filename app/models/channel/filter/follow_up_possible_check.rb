# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Channel::Filter::FollowUpPossibleCheck

  def self.run(_channel, mail, _transaction_params)
    ticket_id = mail[:'x-zammad-ticket-id']
    return true if !ticket_id

    ticket = Ticket.lookup(id: ticket_id)
    return true if !ticket
    return true if !ticket.state.state_type.name.match?(%r{^(closed|merged|removed)}i)

    # For closed tickets, we are checking the follow-up configuration.
    #   In case follow-up is effective, we have to remove follow-up information.
    case ticket.group.follow_up_possible
    when 'new_ticket_after_certain_time'
      if !ticket.reopen_after_certain_time?
        mail[:subject] = ticket.subject_clean(mail[:subject])
        mail[:'x-zammad-ticket-id']     = nil
        mail[:'x-zammad-ticket-number'] = nil
      end
    when 'new_ticket'
      mail[:subject] = ticket.subject_clean(mail[:subject])
      mail[:'x-zammad-ticket-id']     = nil
      mail[:'x-zammad-ticket-number'] = nil
    end

    true
  end
end
