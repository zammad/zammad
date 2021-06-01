# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::FollowUpMerged

  def self.run(_channel, mail, _transaction_params)
    return if mail[:'x-zammad-ticket-id'].blank?

    ticket = Ticket.find_by(id: mail[:'x-zammad-ticket-id'])
    return if ticket.blank?

    ticket = find_merge_follow_up_ticket(ticket)
    return if ticket.blank?

    mail[:'x-zammad-ticket-id'] = ticket.id
  end

  def self.find_merge_follow_up_ticket(ticket)
    return if ticket.state.name != 'merged'

    links = Link.list(
      link_object:       'Ticket',
      link_object_value: ticket.id
    )
    return if links.blank?

    merge_ticket = nil
    links.each do |link|
      next if link['link_type'] != 'parent'
      next if link['link_object'] != 'Ticket'

      check_ticket = Ticket.find_by(id: link['link_object_value'])
      next if check_ticket.blank?

      next if check_ticket.state.name == 'merged'

      merge_ticket = check_ticket
      break
    end
    merge_ticket
  end
end
