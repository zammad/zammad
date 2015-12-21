# Copyright (C) 2012-2015 Zammad Foundation, http://zammad-foundation.org/

require 'facebook'

class Channel::Driver::Facebook

  def fetch (_adapter_options, channel)

    @channel  = channel
    @facebook = Facebook.new( @channel[:options] )
    @sync     = @channel[:options][:sync]

    Rails.logger.debug 'facebook fetch started'

    fetch_feed

    disconnect

    Rails.logger.debug 'facebook fetch completed'
  end

  def send(article, _notification = false)

    @channel  = Channel.find_by( area: 'Facebook::Inbound', active: true )
    @facebook = Facebook.new( @channel[:options] )

    post = @facebook.from_article(article)
    disconnect

    post
  end

  def disconnect
    @facebook.disconnect
  end

  private

  def fetch_feed

    return if !@sync[:group_id]

    counter = 0
    feed    = @facebook.client.get_connections('me', 'feed')
    feed.each { |feed_item|

      break if @sync[:limit] && @sync[:limit] <= counter

      post = @facebook.client.get_object( feed_item['id'] )

      @facebook.to_group( post, @sync[:group_id] )

      counter += 1
    }
  end
end
