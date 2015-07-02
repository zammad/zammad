# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

require 'net/imap'

module Channel::EmailSend
  def self.send(article, notification = false)
    begin
      # we need to require the channel backend individually otherwise we get a
      # 'warning: toplevel constant Twitter referenced by Channel::Twitter' error e.g.
      # so we have to convert the channel name to the filename via Rails String.underscore
      # http://stem.ps/rails/2015/01/25/ruby-gotcha-toplevel-constant-referenced-by.html
      require "channel/#{channel[:adapter].underscore}"

      channel_object   = Object.const_get("Channel::#{channel[:adapter]}")
      channel_instance = channel_object.new

      channel_instance.send(article, channel, notification)

      channel_instance.disconnect
    rescue => e
      Rails.logger.error "Can't use Channel::#{channel[:adapter]}"
      Rails.logger.error e.inspect
      Rails.logger.error e.backtrace
    end
  end
end
