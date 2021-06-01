# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::OwnNotificationLoopDetection

  def self.run(_channel, mail, _transaction_params)

    message_id = mail[:'message-id']
    return if !message_id

    recedence = mail[:precedence]
    return if !recedence
    return if !recedence.match?(%r{bulk}i)

    fqdn = Setting.get('fqdn')
    return if !message_id.match?(%r{@#{Regexp.quote(fqdn)}>}i)

    mail[ :'x-zammad-ignore' ] = true
    Rails.logger.info "Detected own sent notification mail and dropped it to prevent loops (message_id: #{message_id}, from: #{mail[:from]}, to: #{mail[:to]})"

  end
end
