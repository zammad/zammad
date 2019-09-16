# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::OwnNotificationLoopDetection

  def self.run(_channel, mail)

    message_id = mail['message-id'.to_sym]
    return if !message_id

    recedence = mail['precedence'.to_sym]
    return if !recedence
    return if !recedence.match?(/bulk/i)

    fqdn = Setting.get('fqdn')
    return if !message_id.match?(/@#{Regexp.quote(fqdn)}>/i)

    mail[ 'x-zammad-ignore'.to_sym ] = true
    Rails.logger.info "Detected own sent notification mail and dropped it to prevent loops (message_id: #{message_id}, from: #{mail[:from]}, to: #{mail[:to]})"

  end
end
