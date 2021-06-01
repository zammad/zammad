# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'external_credential/twitter'

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

    options = self.class.check_external_credential(options)

    @client  = TwitterSync.new(options[:auth])
    @sync    = options[:sync]
    @channel = channel

    Rails.logger.debug { 'twitter fetch started' }

    fetch_search

    disconnect

    Rails.logger.debug { 'twitter fetch completed' }

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

    options = self.class.check_external_credential(options)

    @client = TwitterSync.new(options[:auth])
    tweet   = @client.from_article(article)
    disconnect
    tweet
  end

  def disconnect
    @client&.disconnect
  end

=begin

  Channel::Driver::Twitter.streamable?

returns

  true|false

=end

  def self.streamable?
    false
  end

=begin

  Channel::Driver::Twitter.process(payload, channel)

=end

  def process(_adapter_options, payload, channel)
    @client = TwitterSync.new(channel.options[:auth], payload)
    @client.process_webhook(channel)
  end

  def self.check_external_credential(options)
    if options[:auth] && options[:auth][:external_credential_id]
      external_credential = ExternalCredential.find_by(id: options[:auth][:external_credential_id])
      raise "No such ExternalCredential.find(#{options[:auth][:external_credential_id]})" if !external_credential

      options[:auth][:consumer_key] = external_credential.credentials['consumer_key']
      options[:auth][:consumer_secret] = external_credential.credentials['consumer_secret']
    end
    options
  end

  private

  def fetch_search
    return if @sync[:search].blank?

    @sync[:search].each do |search|
      next if search[:term].blank?
      next if search[:term] == '#'
      next if search[:group_id].blank?

      result_type = search[:type] || 'mixed'
      Rails.logger.debug { " - searching for '#{search[:term]}'" }
      older_import = 0
      older_import_max = 20
      @client.client.search(search[:term], result_type: result_type).collect do |tweet|
        next if !track_retweets? && tweet.retweet?

        # ignore older messages
        if @sync[:import_older_tweets] != true
          if (@channel.created_at - 15.days) > tweet.created_at.dup.utc || older_import >= older_import_max # rubocop:disable Style/SoleNestedConditional
            older_import += 1
            Rails.logger.debug { "tweet to old: #{tweet.id}/#{tweet.created_at}" }
            next
          end
        end

        next if @client.locale_sender?(tweet) && own_tweet_already_imported?(tweet)
        next if Ticket::Article.exists?(message_id: tweet.id)
        break if @client.tweet_limit_reached(tweet)

        @client.to_group(tweet, search[:group_id], @channel)
      end
    end
  end

  def track_retweets?
    @channel.options && @channel.options['sync'] && @channel.options['sync']['track_retweets']
  end

  def own_tweet_already_imported?(tweet)
    event_time = Time.zone.now
    sleep 4
    12.times do |loop_count|
      if Ticket::Article.exists?(message_id: tweet.id)
        Rails.logger.debug { "Own tweet already imported, skipping tweet #{tweet.id}" }
        return true
      end
      count = Delayed::Job.where('created_at < ?', event_time).count
      break if count.zero?

      sleep_time = 2 * count
      sleep_time = 5 if sleep_time > 5
      Rails.logger.debug { "Delay importing own tweets - sleep #{sleep_time} (loop #{loop_count})" }
      sleep sleep_time
    end

    if Ticket::Article.exists?(message_id: tweet.id)
      Rails.logger.debug { "Own tweet already imported, skipping tweet #{tweet.id}" }
      return true
    end
    false
  end

end
