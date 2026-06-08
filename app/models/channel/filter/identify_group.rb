# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Channel::Filter::IdentifyGroup
  def self.run(channel, mail, _transaction_params)
    return if mail[:'x-zammad-ticket-group'].present? && Group.exists?(name: mail[:'x-zammad-ticket-group'])
    return if mail[:'x-zammad-ticket-group_id'].present? && Group.exists?(id: mail[:'x-zammad-ticket-group_id'])

    mail[:'x-zammad-ticket-group_id'] = find_existing_ticket(mail)&.group_id || pick_group(channel, mail)&.id
  end

  def self.pick_group(channel, mail)
    group = if channel[:group_id]
              Group.lookup(id: channel[:group_id])
            else
              Channel::EmailParser.mail_to_group(mail[:to])
            end

    return group if group&.active

    Group.where(active: true).reorder(id: :asc).first || Group.first
  end

  def self.find_existing_ticket(mail)
    if mail[:'x-zammad-ticket-number'].present?
      ticket_by_number = Ticket.find_by(number: mail[:'x-zammad-ticket-number'])

      return ticket_by_number if ticket_by_number
    end

    if mail[:'x-zammad-ticket-id'].present?
      return Ticket.find_by(id: mail[:'x-zammad-ticket-id'])
    end

    nil
  end
end
