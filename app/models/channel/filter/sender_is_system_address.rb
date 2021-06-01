# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::SenderIsSystemAddress

  def self.run(_channel, mail, _transaction_params)

    # if attributes already set by header
    return if mail[:'x-zammad-ticket-create-article-sender']
    return if mail[:'x-zammad-article-sender']

    # check if sender address is system
    form = :'raw-from'
    return if mail[form].blank?
    return if mail[:to].blank?

    # in case, set sender
    begin
      return if !mail[form].addrs

      items = mail[form].addrs
      items.each do |item|
        next if !EmailAddress.exists?(email: item.address.downcase)

        mail[:'x-zammad-ticket-create-article-sender'] = 'Agent'
        mail[:'x-zammad-article-sender']               = 'Agent'
        return true
      end
    rescue => e
      Rails.logger.error "SenderIsSystemAddress: #{e.inspect}"
    end

    # check if sender is agent
    return if mail[:from_email].blank?

    begin
      user = User.find_by(email: mail[:from_email].downcase)
      return if !user
      return if !user.permissions?('ticket.agent')

      mail[:'x-zammad-ticket-create-article-sender'] = 'Agent'
      mail[:'x-zammad-article-sender']               = 'Agent'

      # if the agent is also customer of the ticket then
      # we need to set the sender as customer.
      ticket_id = mail[:'x-zammad-ticket-id']
      if ticket_id.present?
        ticket = Ticket.lookup(id: ticket_id)

        if ticket.present? && ticket.customer_id == user.id
          mail[:'x-zammad-ticket-create-article-sender'] = 'Customer'
          mail[:'x-zammad-article-sender']               = 'Customer'
        end
      end
      return true
    rescue => e
      Rails.logger.error "SenderIsSystemAddress: #{e.inspect}"
    end

    true
  end
end
