# Copyright (C) 2012-2015 Zammad Foundation, http://zammad-foundation.org/

class TweetRest < TweetBase

  attr_accessor :client

  def initialize(auth)
    @connection_type = 'rest'
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key        = auth[:consumer_key]
      config.consumer_secret     = auth[:consumer_secret]
      config.access_token        = auth[:oauth_token]
      config.access_token_secret = auth[:oauth_token_secret]
    end

  end

  def disconnect
    return if !@client
    @client = nil
  end

end
