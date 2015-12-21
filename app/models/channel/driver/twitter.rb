# Copyright (C) 2012-2015 Zammad Foundation, http://zammad-foundation.org/

=begin

fetch tweets from twitter account

  options = {
    adapter: 'twitter',
    auth: {
      consumer_key:       consumer_key,
      consumer_secret:    consumer_secret,
      oauth_token:        armin_theo_token,
      oauth_token_secret: armin_theo_token_secret,
    },
    sync: {
      search: [
        {
          term: '#citheo42',
          group_id: 2,
        },
        {
          term: '#citheo24',
          group_id: 1,
        },
      ],
      mentions: {
        group_id: 2,
      },
      direct_messages: {
        group_id: 2,
      }
    }
  }

  instance = Channel::Driver::Twitter.new
  result = instance.fetch(options, channel)

returns

  {
    result: 'ok',
  }

=end

class Channel::Driver::Twitter

  def fetch (options, channel)

    options = check_external_credential(options)

    @tweet   = Tweet.new(options[:auth])
    @sync    = options[:sync]
    @channel = channel

    Rails.logger.debug 'twitter fetch started'

    fetch_search
    fetch_mentions
    fetch_direct_messages

    disconnect

    Rails.logger.debug 'twitter fetch completed'

    {
      result: 'ok',
    }
  end

=begin

  instance = Channel::Driver::Twitter.new
  instance.send(
    {
      adapter: 'twitter',
      auth: {
        consumer_key:       consumer_key,
        consumer_secret:    consumer_secret,
        oauth_token:        armin_theo_token,
        oauth_token_secret: armin_theo_token_secret,
      },
    },
    twitter_attributes,
    notification
  )

=end

  def send(options, article, _notification = false)

    # return if we run import mode
    return if Setting.get('import_mode')

    options = check_external_credential(options)

    @tweet = Tweet.new(options[:auth])
    tweet  = @tweet.from_article(article)
    disconnect
    tweet
  end

  def disconnect
    @tweet.disconnect
  end

  private

  def fetch_search

    return if !@sync[:search]
    return if @sync[:search].empty?

    # search results
    @sync[:search].each { |search|

      result_type = search[:type] || 'mixed'

      Rails.logger.debug " - searching for '#{search[:term]}'"

      counter = 0
      @tweet.client.search(search[:term], result_type: result_type).collect { |tweet|

        break if search[:limit] && search[:limit] <= counter
        break if Ticket::Article.find_by(message_id: tweet.id)

        @tweet.to_group(tweet, search[:group_id], @channel)

        counter += 1
      }
    }
  end

  def fetch_mentions

    return if !@sync[:mentions]
    return if @sync[:mentions].empty?

    Rails.logger.debug ' - searching for mentions'

    counter = 0
    @tweet.client.mentions_timeline.each { |tweet|

      break if @sync[:mentions][:limit] && @sync[:mentions][:limit] <= counter
      break if Ticket::Article.find_by(message_id: tweet.id)

      @tweet.to_group(tweet, @sync[:mentions][:group_id], @channel)

      counter += 1
    }
  end

  def fetch_direct_messages

    return if !@sync[:direct_messages]
    return if @sync[:direct_messages].empty?

    Rails.logger.debug ' - searching for direct_messages'

    counter = 0
    @tweet.client.direct_messages.each { |tweet|

      break if @sync[:direct_messages][:limit] && @sync[:direct_messages][:limit] <= counter
      break if Ticket::Article.find_by(message_id: tweet.id)

      @tweet.to_group(tweet, @sync[:direct_messages][:group_id], @channel)

      counter += 1
    }
  end

  def check_external_credential(options)
    if options[:auth] && options[:auth][:external_credential_id]
      external_credential = ExternalCredential.find_by(id: options[:auth][:external_credential_id])
      fail "No such ExternalCredential.find(#{options[:auth][:external_credential_id]})" if !external_credential
      options[:auth][:consumer_key] = external_credential.credentials['consumer_key']
      options[:auth][:consumer_secret] = external_credential.credentials['consumer_secret']
    end
    options
  end

end
