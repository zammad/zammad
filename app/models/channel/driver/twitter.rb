# Copyright (C) 2012-2015 Zammad Foundation, http://zammad-foundation.org/

class Channel::Driver::Twitter

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

  def fetch(options, channel)

    options = check_external_credential(options)

    @rest_client = TweetRest.new(options[:auth])
    @sync        = options[:sync]
    @channel     = channel

    Rails.logger.debug 'twitter fetch started'

    fetch_mentions
    fetch_search
    fetch_direct_messages

    disconnect

    Rails.logger.debug 'twitter fetch completed'

    {
      result: 'ok',
      notice: '',
    }
  end

=begin

  instance = Channel::Driver::Twitter.new
  instance.fetchable?(channel)

=end

  def fetchable?(channel)
    return true if Rails.env.test?

    # only fetch once in 30 minutes
    return true if !channel.preferences
    return true if !channel.preferences[:last_fetch]
    return false if channel.preferences[:last_fetch] > Time.zone.now - 30.minutes
    true
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

    @rest_client = TweetRest.new(options[:auth])
    tweet        = @rest_client.from_article(article)
    disconnect
    tweet
  end

  def disconnect
    @stream_client.disconnect if @stream_client
    @rest_client.disconnect if @rest_client
  end

=begin

create stream endpoint form twitter account

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
  stream_instance = instance.stream_instance(channel)

returns

  instance_of_stream_handle

=end

  def stream_instance(channel)
    @channel = channel
    options = @channel.options
    @stream_client = TweetStream.new(options[:auth])
  end

=begin

stream tweets from twitter account

  instance.stream

returns

  # endless loop

=end

  def stream
    sync = @channel.options['sync']
    raise 'Need channel.options[\'sync\'] for account, but no params found' if !sync

    filter = {}
    if sync['search']
      hashtags = []
      sync['search'].each { |item|
        hashtags.push item['term']
      }
      filter[:track] = hashtags.join(',')
    end
    if sync['mentions'] && sync['mentions']['group_id'] != ''
      filter[:replies] = 'all'
    end

    return if filter.empty?

    @stream_client.client.user(filter) do |tweet|
      next if tweet.class != Twitter::Tweet && tweet.class != Twitter::DirectMessage
      next if Ticket::Article.find_by(message_id: tweet.id)

      # check direct message
      if tweet.class == Twitter::DirectMessage
        if sync['direct_messages'] && sync['direct_messages']['group_id'] != ''
          next if @stream_client.direct_message_limit_reached(tweet)
          @stream_client.to_group(tweet, sync['direct_messages']['group_id'], @channel)
        end
        next
      end

      next if @stream_client.tweet_limit_reached(tweet)

      # check if it's mention
      if sync['mentions'] && sync['mentions']['group_id'] != ''
        hit = false
        if tweet.user_mentions
          tweet.user_mentions.each { |user|
            if user.id.to_s == @channel.options['user']['id'].to_s
              hit = true
            end
          }
        end
        if hit
          @stream_client.to_group(tweet, sync['mentions']['group_id'], @channel)
          next
        end
      end

      # check hashtags
      if sync['search'] && tweet.hashtags
        hit = false
        sync['search'].each { |item|
          tweet.hashtags.each { |hashtag|
            next if item['term'] !~ /^#/
            if item['term'].sub(/^#/, '') == hashtag.text
              hit = item
            end
          }
        }
        if hit
          @stream_client.to_group(tweet, hit['group_id'], @channel)
          next
        end
      end

      # check stings
      if sync['search']
        hit = false
        body = tweet.text
        sync['search'].each { |item|
          next if item['term'] =~ /^#/
          if body =~ /#{item['term']}/
            hit = item
          end
        }
        if hit
          @stream_client.to_group(tweet, hit['group_id'], @channel)
        end
      end

    end
  end

  private

  def fetch_search
    return if !@sync[:search]
    return if @sync[:search].empty?
    @sync[:search].each { |search|
      next if !search[:term]
      next if search[:term].to_s.empty?
      next if !search[:group_id]
      next if search[:group_id].to_s.empty?
      result_type = search[:type] || 'mixed'
      Rails.logger.debug " - searching for '#{search[:term]}'"
      older_import = 0
      older_import_max = 20
      @rest_client.client.search(search[:term], result_type: result_type).collect { |tweet|

        # ignore older messages
        if (@channel.created_at - 15.days) > tweet.created_at || older_import >= older_import_max
          older_import += 1
          Rails.logger.debug "tweet to old: #{tweet.id}/#{tweet.created_at}"
          next
        end
        next if Ticket::Article.find_by(message_id: tweet.id)
        break if @rest_client.tweet_limit_reached(tweet)
        @rest_client.to_group(tweet, search[:group_id], @channel)
      }
    }
  end

  def fetch_mentions
    return if !@sync[:mentions]
    return if @sync[:mentions].empty?
    return if !@sync[:mentions][:group_id]
    return if @sync[:mentions][:group_id].to_s.empty?
    Rails.logger.debug ' - searching for mentions'
    older_import = 0
    older_import_max = 20
    @rest_client.client.mentions_timeline.each { |tweet|

      # ignore older messages
      if (@channel.created_at - 15.days) > tweet.created_at || older_import >= older_import_max
        older_import += 1
        Rails.logger.debug "tweet to old: #{tweet.id}/#{tweet.created_at}"
        next
      end
      next if Ticket::Article.find_by(message_id: tweet.id)
      break if @rest_client.tweet_limit_reached(tweet)
      @rest_client.to_group(tweet, @sync[:mentions][:group_id], @channel)
    }
  end

  def fetch_direct_messages
    return if !@sync[:direct_messages]
    return if @sync[:direct_messages].empty?
    return if !@sync[:direct_messages][:group_id]
    return if @sync[:direct_messages][:group_id].to_s.empty?
    Rails.logger.debug ' - searching for direct_messages'
    older_import = 0
    older_import_max = 20
    @rest_client.client.direct_messages.each { |tweet|

      # ignore older messages
      if (@channel.created_at - 15.days) > tweet.created_at || older_import >= older_import_max
        older_import += 1
        Rails.logger.debug "tweet to old: #{tweet.id}/#{tweet.created_at}"
        next
      end
      next if Ticket::Article.find_by(message_id: tweet.id)
      break if @rest_client.direct_message_limit_reached(tweet)
      @rest_client.to_group(tweet, @sync[:direct_messages][:group_id], @channel)
    }
  end

  def check_external_credential(options)
    if options[:auth] && options[:auth][:external_credential_id]
      external_credential = ExternalCredential.find_by(id: options[:auth][:external_credential_id])
      raise "No such ExternalCredential.find(#{options[:auth][:external_credential_id]})" if !external_credential
      options[:auth][:consumer_key] = external_credential.credentials['consumer_key']
      options[:auth][:consumer_secret] = external_credential.credentials['consumer_secret']
    end
    options
  end

end
