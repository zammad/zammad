# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module RSpecTwitter
  class Helper
    attr_accessor :twitter_client, :user_screen_name

    def initialize(auth)
      @twitter_client = TwitterSync.new(
        consumer_key:       auth[:consumer_key],
        consumer_secret:    auth[:consumer_secret],
        oauth_token:        auth[:oauth_token],
        oauth_token_secret: auth[:oauth_token_secret],
      )

      @user_screen_name = 'APITesting00x'

      return if !live_mode?

      @user_screen_name = @twitter_client.client.user.screen_name

    end

    def delete_old_tweets
      log('I\'m deleting tweets older than one hour...')

      tweets = current_tweets.select { |tweet| tweet.created_at < 1.hour.ago }
      while tweets.size.positive?
        perform_delete(tweets, nil, [])

        tweets = current_tweets.select { |tweet| tweet.created_at < 1.hour.ago }
      end
    end

    def delete_all_tweets(identifier = nil)
      log('I\'m deleting all tweets...') if identifier.nil?
      log("I'm deleting all tweets matching identifier '#{identifier}...'") if identifier.present?

      tweets = current_tweets
      tweets_to_ignore = []
      while tweets.size.positive?
        perform_delete(tweets, identifier, tweets_to_ignore)

        tweets = current_tweets.reject { |tweet| tweets_to_ignore.include?(tweet.id) }
      end
    end

    def perform_delete(tweets, identifier, ignore_list)
      tweets.each do |tweet|
        next if !tweet_exists?(tweet)
        next if ignore_list.include?(tweet.id)

        if tweet_match?(tweet, identifier)
          delete_tweet(tweet)
          next
        end

        ignore_list << tweet.id
      end

      nil
    end

    def current_tweets
      twitter_client.client.user_timeline({ count: 200 })
    end

    def tweet_match?(tweet, identifier)
      return true if identifier.nil?
      return true if identifier.present? && tweet.text.include?(identifier)

      false
    end

    def tweet_exists?(tweet)
      twitter_client.client.status(tweet)&.present?
    rescue
      false
    end

    def create_tweet(status, options = {})
      log("Creating tweet '#{status}'...")

      twitter_client.client.update(status, options)
    end

    def delete_tweet(tweet)
      log("Deleting tweet with id #{tweet.id}...")

      twitter_client.client.destroy_status(tweet)
    rescue
      nil
    end

    def create_retweet(id)
      log("Creating retweet for tweet '#{id}'...")

      twitter_client.client.retweet(id)
    end

    def ensure_tweet_availability(identifier, amount)
      log("Ensuring availability of #{amount} tweets with identifier '#{identifier}'...")

      time_now = Time.zone.now
      while Time.zone.now < time_now + 120.seconds
        if twitter_client.client.search(identifier, result_type: 'mixed').attrs[:statuses].count.eql?(amount)
          log("Found #{amount} tweets for '#{identifier}'. Amazing!")
          return true
        end

        # Only fall asleep if we're not using cassettes.
        if live_mode?
          log("Waiting 30 seconds for tweets to show up in search results (#{identifier})...")
          sleep 30
        end
      end

      log("Could not find #{amount} tweets for '#{identifier}' within 120 seconds. Giving up.")

      false
    end

    def live_mode?
      %w[1 true].include?(ENV['CI_IGNORE_CASSETTES'])
    end

    def log(msg)
      Rails.logger.debug { "[TWITTER > #{user_screen_name}] #{msg}" }
    end
  end
end

RSpec.configure do |config|
  config.include RSpecTwitter
end
