# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Channel < ApplicationModel
  store :options

  def self.fetch
    channels = Channel.where( 'active = ? AND area LIKE ?', true, '%::Inbound' )
    channels.each { |channel|
      begin
        c = eval 'Channel::' + channel[:adapter] + '.new'
        c.fetch(channel)
      rescue Exception => e
        puts "can't use " + 'Channel::' + channel[:adapter]
        puts e.inspect
        puts e.backtrace
        c.disconnect
      end
    }
  end
end
