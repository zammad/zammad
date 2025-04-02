# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Channel::Filter::FollowUpMerged

  def self.run(_channel, mail, _transaction_params)
    return if mail[:'x-zammad-ticket-id'].blank?

    referenced_ticket = Ticket.find_by(id: mail[:'x-zammad-ticket-id'])
    return if referenced_ticket.blank?

    new_target_ticket = find_merge_follow_up_ticket(referenced_ticket)
    return if new_target_ticket.blank?

    mail[:'x-zammad-ticket-id'] = new_target_ticket.id
  end

  # Returns ticket the given ticket was merged into
  def self.find_merge_follow_up_ticket(ticket)
    return if ticket.state.state_type.name != 'merged'

    Link
      .list(
        link_object:       'Ticket',
        link_object_value: ticket.id
      ).lazy
      .filter_map do |link|
        next if link['link_type'] != 'parent'
        next if link['link_object'] != 'Ticket'

        Ticket
          .joins(state: :state_type)
          .where.not(ticket_state_types: { name: 'merged' })
          .find_by(id: link['link_object_value'])
      end
      .first
  end
end
