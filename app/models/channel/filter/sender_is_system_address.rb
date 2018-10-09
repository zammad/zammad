# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::SenderIsSystemAddress

  def self.run(_channel, mail)

    # if attributes already set by header
    return if mail['x-zammad-ticket-create-article-sender'.to_sym]
    return if mail['x-zammad-article-sender'.to_sym]

    # check if sender address is system
    form = 'raw-from'.to_sym
    return if mail[form].blank?
    return if mail[:to].blank?

    # in case, set sender
    begin
      return if !mail[form].addrs

      items = mail[form].addrs
      items.each do |item|
        next if !EmailAddress.find_by(email: item.address.downcase)

        mail['x-zammad-ticket-create-article-sender'.to_sym] = 'Agent'
        mail['x-zammad-article-sender'.to_sym] = 'Agent'
        return true
      end
    rescue => e
      Rails.logger.error 'ERROR: SenderIsSystemAddress: ' + e.inspect
    end

    # check if sender is agent
    return if mail[:from_email].blank?

    begin
      user = User.find_by(email: mail[:from_email].downcase)
      return if !user
      return if !user.permissions?('ticket.agent')

      mail['x-zammad-ticket-create-article-sender'.to_sym] = 'Agent'
      mail['x-zammad-article-sender'.to_sym] = 'Agent'
      return true
    rescue => e
      Rails.logger.error 'ERROR: SenderIsSystemAddress: ' + e.inspect
    end

    true
  end
end
