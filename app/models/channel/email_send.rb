# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

require 'net/imap'

module Channel::EmailSend
  def self.send(attr, notification = false)
    channel = Channel.where( area: 'Email::Outbound', active: true ).first
    begin
      c = eval 'Channel::' + channel[:adapter] + '.new'
      c.send(attr, channel, notification)
    rescue Exception => e
      Rails.logger.error "can't use " + 'Channel::' + channel[:adapter]
      Rails.logger.error e.inspect
      Rails.logger.error e.backtrace
    end
  end
end
