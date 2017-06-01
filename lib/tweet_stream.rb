# Copyright (C) 2012-2015 Zammad Foundation, http://zammad-foundation.org/

class TweetStream < TweetBase

  attr_accessor :client

  def initialize(auth)
    @connection_type = 'stream'
    @auth = auth
    @client = Twitter::Streaming::ClientCustom.new do |config|
      config.consumer_key        = auth[:consumer_key]
      config.consumer_secret     = auth[:consumer_secret]
      config.access_token        = auth[:oauth_token]
      config.access_token_secret = auth[:oauth_token_secret]
    end

  end

  def disconnect
    if @client && @client.custom_connection_handle
      @client.custom_connection_handle.close
    end

    return if !@client
    @client = nil
  end

end
