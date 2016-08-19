# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::SenderIsSystemAddress

  def self.run(_channel, mail)

    # if attributes already set by header
    return if mail[ 'x-zammad-ticket-create-article-sender'.to_sym ]
    return if mail[ 'x-zammad-article-sender'.to_sym ]

    # check if sender addesss is system
    form = 'raw-from'.to_sym
    return if !mail[form]
    return if !mail[:to]

    # in case, set sender
    begin
      return if !mail[form].addrs
      items = mail[form].addrs
      items.each { |item|
        next if !EmailAddress.find_by(email: item.address.downcase)
        mail[ 'x-zammad-ticket-create-article-sender'.to_sym ] = 'Agent'
        mail[ 'x-zammad-article-sender'.to_sym ] = 'Agent'
        return true
      }
    rescue => e
      Rails.logger.error 'ERROR: SenderIsSystemAddress: ' + e.inspect
    end

    true
  end
end
