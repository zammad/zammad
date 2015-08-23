# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Channel < ApplicationModel
  store :options

  def self.fetch
    channels = Channel.where( 'active = ? AND area LIKE ?', true, '%::Inbound' )
    channels.each { |channel|
      begin
        # we need to require each channel backend individually otherwise we get a
        # 'warning: toplevel constant Twitter referenced by Channel::Twitter' error e.g.
        # so we have to convert the channel name to the filename via Rails String.underscore
        # http://stem.ps/rails/2015/01/25/ruby-gotcha-toplevel-constant-referenced-by.html
        require "channel/#{channel[:adapter].to_filename}"

        channel_object   = Object.const_get("Channel::#{channel[:adapter].to_classname}")
        channel_instance = channel_object.new
        channel_instance.fetch(channel)
      rescue => e
        logger.error "Can't use Channel::#{channel[:adapter].to_classname}"
        logger.error e.inspect
        logger.error e.backtrace
      end
    }
  end
end
