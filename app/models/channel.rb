# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Channel < ApplicationModel
  store :options

  def self.fetch
    channels = Channel.where( 'active = ? AND area LIKE ?', true, '%::Inbound' )
    channels.each { |channel|
      begin
        c = eval 'Channel::' + channel[:adapter].upcase + '.new' # rubocop:disable Lint/Eval
        c.fetch(channel)
      rescue => e
        logger.error "can't use " + 'Channel::' + channel[:adapter].upcase
        logger.error e.inspect
        logger.error e.backtrace
        c.disconnect
      end
    }
  end
end
