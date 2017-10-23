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
    return false if channel.preferences[:last_fetch] > Time.zone.now - 20.minutes
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

  Channel::Driver::Twitter.streamable?

returns

  true|false

=end

  def self.streamable?
    true
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
    sleep_on_unauthorized = 65
    2.times do |loop_count|
      begin
        stream_start
      rescue Twitter::Error::Unauthorized => e
        Rails.logger.info "Unable to stream, try #{loop_count}, error #{e.inspect}"
        if loop_count < 2
          Rails.logger.info "wait for #{sleep_on_unauthorized} sec. and try it again"
          sleep sleep_on_unauthorized
        else
          raise "Unable to stream, try #{loop_count}, error #{e.inspect}"
        end
      end
    end
  end

  def stream_start

    sync = @channel.options['sync']
    raise 'Need channel.options[\'sync\'] for account, but no params found' if !sync

    filter = {}
    if sync['search']
      hashtags = []
      sync['search'].each do |item|
        next if item['term'].blank?
        next if item['group_id'].blank?
        hashtags.push item['term']
      end
      filter[:track] = hashtags.join(',')
    end
    if sync['mentions'] && sync['mentions']['group_id'] != ''
      filter[:replies] = 'all'
    end

    return if filter.empty?

    @stream_client.client.user(filter) do |tweet|
      next if tweet.class != Twitter::Tweet && tweet.class != Twitter::DirectMessage

      # wait until own posts are stored in local database to prevent importing own tweets
      next if @stream_client.locale_sender?(tweet) && own_tweet_already_imported?(tweet)

      next if Ticket::Article.find_by(message_id: tweet.id)

      # check direct message
      if tweet.class == Twitter::DirectMessage
        if sync['direct_messages'] && sync['direct_messages']['group_id'] != ''
          next if @stream_client.direct_message_limit_reached(tweet, 2)
          @stream_client.to_group(tweet, sync['direct_messages']['group_id'], @channel)
        end
        next
      end

      next if !track_retweets? && tweet.retweet?
      next if @stream_client.tweet_limit_reached(tweet, 2)

      # check if it's mention
      if sync['mentions'] && sync['mentions']['group_id'].present?
        hit = false
        if tweet.user_mentions
          tweet.user_mentions.each do |user|
            if user.id.to_s == @channel.options['user']['id'].to_s
              hit = true
            end
          end
        end
        if hit
          @stream_client.to_group(tweet, sync['mentions']['group_id'], @channel)
          next
        end
      end

      # check hashtags
      if sync['search'] && tweet.hashtags
        hit = false
        sync['search'].each do |item|
          next if item['term'].blank?
          next if item['group_id'].blank?
          tweet.hashtags.each do |hashtag|
            next if item['term'] !~ /^#/
            if item['term'].sub(/^#/, '') == hashtag.text
              hit = item
            end
          end
        end
        if hit
          @stream_client.to_group(tweet, hit['group_id'], @channel)
          next
        end
      end

      # check stings
      if sync['search']
        hit = false
        body = tweet.text
        sync['search'].each do |item|
          next if item['term'].blank?
          next if item['group_id'].blank?
          if body =~ /#{item['term']}/
            hit = item
          end
        end
        if hit
          @stream_client.to_group(tweet, hit['group_id'], @channel)
        end
      end

    end
  end

  private

  def fetch_search
    return if @sync[:search].blank?
    @sync[:search].each do |search|
      next if search[:term].blank?
      next if search[:group_id].blank?
      result_type = search[:type] || 'mixed'
      Rails.logger.debug " - searching for '#{search[:term]}'"
      older_import = 0
      older_import_max = 20
      @rest_client.client.search(search[:term], result_type: result_type).collect do |tweet|
        next if !track_retweets? && tweet.retweet?

        # ignore older messages
        if (@channel.created_at - 15.days) > tweet.created_at.dup.utc || older_import >= older_import_max
          older_import += 1
          Rails.logger.debug "tweet to old: #{tweet.id}/#{tweet.created_at}"
          next
        end

        next if @rest_client.locale_sender?(tweet) && own_tweet_already_imported?(tweet)
        next if Ticket::Article.find_by(message_id: tweet.id)
        break if @rest_client.tweet_limit_reached(tweet)
        @rest_client.to_group(tweet, search[:group_id], @channel)
      end
    end
  end

  def fetch_mentions
    return if @sync[:mentions].blank?
    return if @sync[:mentions][:group_id].blank?
    Rails.logger.debug ' - searching for mentions'
    older_import = 0
    older_import_max = 20
    @rest_client.client.mentions_timeline.each do |tweet|
      next if !track_retweets? && tweet.retweet?

      # ignore older messages
      if (@channel.created_at - 15.days) > tweet.created_at.dup.utc || older_import >= older_import_max
        older_import += 1
        Rails.logger.debug "tweet to old: #{tweet.id}/#{tweet.created_at}"
        next
      end
      next if Ticket::Article.find_by(message_id: tweet.id)
      break if @rest_client.tweet_limit_reached(tweet)
      @rest_client.to_group(tweet, @sync[:mentions][:group_id], @channel)
    end
  end

  def fetch_direct_messages
    return if @sync[:direct_messages].blank?
    return if @sync[:direct_messages][:group_id].blank?
    Rails.logger.debug ' - searching for direct_messages'
    older_import = 0
    older_import_max = 20
    @rest_client.client.direct_messages(full_text: 'true').each do |tweet|

      # ignore older messages
      if (@channel.created_at - 15.days) > tweet.created_at.dup.utc || older_import >= older_import_max
        older_import += 1
        Rails.logger.debug "tweet to old: #{tweet.id}/#{tweet.created_at}"
        next
      end
      next if Ticket::Article.find_by(message_id: tweet.id)
      break if @rest_client.direct_message_limit_reached(tweet)
      @rest_client.to_group(tweet, @sync[:direct_messages][:group_id], @channel)
    end
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

  def track_retweets?
    @channel.options && @channel.options['sync'] && @channel.options['sync']['track_retweets']
  end

  def own_tweet_already_imported?(tweet)
    event_time = Time.zone.now
    sleep 4
    12.times do |loop_count|
      if Ticket::Article.find_by(message_id: tweet.id)
        Rails.logger.debug "Own tweet already imported, skipping tweet #{tweet.id}"
        return true
      end
      count = Delayed::Job.where('created_at < ?', event_time).count
      break if count.zero?
      sleep_time = 2 * count
      sleep_time = 5 if sleep_time > 5
      Rails.logger.debug "Delay importing own tweets - sleep #{sleep_time} (loop #{loop_count})"
      sleep sleep_time
    end

    if Ticket::Article.find_by(message_id: tweet.id)
      Rails.logger.debug "Own tweet already imported, skipping tweet #{tweet.id}"
      return true
    end
    false
  end

end
