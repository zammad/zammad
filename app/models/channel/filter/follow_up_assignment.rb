# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Channel::Filter::FollowUpAssignment

  def self.run(_channel, mail, _transaction_params)
    return if !mail[:'x-zammad-ticket-id']

    ticket = Ticket.lookup(id: mail[:'x-zammad-ticket-id'])

    return if ticket.blank?
    return if ticket.state.state_type.name != 'closed'
    return if ticket.group.follow_up_assignment

    mail[:'x-zammad-ticket-followup-owner'] = User.lookup(id: 1).login

    true
  end
end
