# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'http/uri'

class TwitterSync

  STATUS_URL_TEMPLATE = 'https://twitter.com/_/status/%s'.freeze
  DM_URL_TEMPLATE = 'https://twitter.com/messages/%s'.freeze

  attr_accessor :client

  def initialize(auth, payload = nil)
    @client = Twitter::REST::Client.new(
      consumer_key:        auth[:consumer_key],
      consumer_secret:     auth[:consumer_secret],
      access_token:        auth[:oauth_token] || auth[:access_token],
      access_token_secret: auth[:oauth_token_secret] || auth[:access_token_secret],
    )
    @payload = payload
  end

  def disconnect
    return if !@client

    @client = nil
  end

  def user(tweet)
    raise "Unknown tweet type '#{tweet.class}'" if tweet.class != Twitter::Tweet

    Rails.logger.debug { "Twitter sender for tweet (#{tweet.id}): found" }
    Rails.logger.debug { tweet.user.inspect }
    tweet.user
  end

  def to_user(tweet)

    Rails.logger.debug { 'Create user from tweet...' }
    Rails.logger.debug { tweet.inspect }

    # do tweet_user lookup
    tweet_user = user(tweet)

    auth = Authorization.find_by(uid: tweet_user.id, provider: 'twitter')

    # create or update user
    user_data = {
      image_source: tweet_user.profile_image_url.to_s,
    }
    if auth
      user = User.find(auth.user_id)
      map = {
        note:    'description',
        web:     'website',
        address: 'location',
      }

      # ignore if value is already set
      map.each do |target, source|
        next if user[target].present?

        new_value = tweet_user.send(source).to_s
        next if new_value.blank?

        user_data[target] = new_value
      end
      user.update!(user_data)
    else
      user_data[:login]     = tweet_user.screen_name
      user_data[:firstname] = tweet_user.name
      user_data[:web]       = tweet_user.website.to_s
      user_data[:note]      = tweet_user.description
      user_data[:address]   = tweet_user.location
      user_data[:active]    = true
      user_data[:role_ids]  = Role.signup_role_ids

      user = User.create!(user_data)
    end

    if user_data[:image_source]
      avatar = Avatar.add(
        object:        'User',
        o_id:          user.id,
        url:           user_data[:image_source],
        source:        'twitter',
        deletable:     true,
        updated_by_id: user.id,
        created_by_id: user.id,
      )

      # update user link
      if avatar && user.image != avatar.store_hash
        user.image = avatar.store_hash
        user.save
      end
    end

    # create or update authorization
    auth_data = {
      uid:      tweet_user.id,
      username: tweet_user.screen_name,
      user_id:  user.id,
      provider: 'twitter'
    }
    if auth
      auth.update!(auth_data)
    else
      Authorization.create!(auth_data)
    end

    user
  end

  def to_ticket(tweet, user, group_id, channel)
    UserInfo.current_user_id = user.id

    Rails.logger.debug { 'Create ticket from tweet...' }
    Rails.logger.debug { tweet.inspect }
    Rails.logger.debug { user.inspect }
    Rails.logger.debug { group_id.inspect }

    # normalize message
    message = {}

    if tweet.instance_of?(Twitter::Tweet)
      message = {
        type: 'tweet',
        text: tweet.text,
      }
      state = get_state(channel, tweet)
    end

    if tweet.is_a?(Hash) && tweet['type'] == 'message_create'
      message = {
        type: 'direct_message',
        text: tweet['message_create']['message_data']['text'],
      }
      state = get_state(channel, tweet)
    end

    if tweet.is_a?(Hash) && tweet['text'].present?
      message = {
        type: 'tweet',
        text: tweet['text'],
      }
      state = get_state(channel, tweet)
    end

    # process message
    if message[:type] == 'direct_message'
      ticket = Ticket.find_by(
        create_article_type: Ticket::Article::Type.lookup(name: 'twitter direct-message'),
        customer_id:         user.id,
        state:               Ticket::State.where.not(
          state_type_id: Ticket::StateType.where(
            name: %w[closed merged removed],
          )
        )
      )
      return ticket if ticket
    end

    # prepare title
    title = message[:text]
    if title.length > 80
      title = "#{title[0, 80]}..."
    end

    Ticket.create!(
      customer_id: user.id,
      title:       title,
      group_id:    group_id || Group.first.id,
      state:       state,
      priority:    Ticket::Priority.find_by(default_create: true),
      preferences: {
        channel_id:          channel.id,
        channel_screen_name: channel.options['user']['screen_name'],
      },
    )
  end

  def to_article_webhook(item, user, ticket, channel)

    Rails.logger.debug { 'Create article from tweet...' }
    Rails.logger.debug { item.inspect }
    Rails.logger.debug { user.inspect }
    Rails.logger.debug { ticket.inspect }

    # import tweet
    to = nil
    from = nil
    text = nil
    message_id = nil
    article_type = nil
    in_reply_to = nil
    attachments = []

    if item['type'] == 'message_create'
      message_id = item['id']
      text = item['message_create']['message_data']['text']
      if item['message_create']['message_data']['entities'] && item['message_create']['message_data']['entities']['urls'].present?
        item['message_create']['message_data']['entities']['urls'].each do |local_url|
          next if local_url['url'].blank?

          if local_url['expanded_url'].present?
            text.gsub!(%r{#{Regexp.quote(local_url['url'])}}, local_url['expanded_url'])
          elsif local_url['display_url']
            text.gsub!(%r{#{Regexp.quote(local_url['url'])}}, local_url['display_url'])
          end
        end
      end

      app = get_app_webhook(item['message_create']['source_app_id'])
      article_type = 'twitter direct-message'
      recipient_id = item['message_create']['target']['recipient_id']
      recipient_screen_name = to_user_webhook_data(item['message_create']['target']['recipient_id'])['screen_name']
      sender_id = item['message_create']['sender_id']
      sender_screen_name = to_user_webhook_data(item['message_create']['sender_id'])['screen_name']
      to = "@#{recipient_screen_name}"
      from = "@#{sender_screen_name}"

      twitter_preferences = {
        created_at:            item['created_timestamp'],
        recipient_id:          recipient_id,
        recipient_screen_name: recipient_screen_name,
        sender_id:             sender_id,
        sender_screen_name:    sender_screen_name,
        app_id:                app['app_id'],
        app_name:              app['app_name'],
      }

      article_preferences = {
        twitter: self.class.preferences_cleanup(twitter_preferences),
        links:   [
          {
            url:    DM_URL_TEMPLATE % [recipient_id, sender_id].map(&:to_i).sort.join('-'),
            target: '_blank',
            name:   'on Twitter',
          },
        ],
      }

    elsif item['text'].present?
      message_id = item['id']
      text = item['text']
      if item['extended_tweet'] && item['extended_tweet']['full_text'].present?
        text = item['extended_tweet']['full_text']
      end
      article_type = 'twitter status'
      sender_screen_name = item['user']['screen_name']
      from = "@#{sender_screen_name}"
      mention_ids = []
      if item['entities']

        item['entities']['user_mentions']&.each do |local_user|
          if to
            to += ', '
          else
            to = ''
          end
          to += "@#{local_user['screen_name']}"
          mention_ids.push local_user['id']
        end

        item['entities']['urls']&.each do |local_media|

          if local_media['url'].present?
            if local_media['expanded_url'].present?
              text.gsub!(%r{#{Regexp.quote(local_media['url'])}}, local_media['expanded_url'])
            elsif local_media['display_url']
              text.gsub!(%r{#{Regexp.quote(local_media['url'])}}, local_media['display_url'])
            end
          end
        end

        item['entities']['media']&.each do |local_media|

          if local_media['url'].present?
            if local_media['expanded_url'].present?
              text.gsub!(%r{#{Regexp.quote(local_media['url'])}}, local_media['expanded_url'])
            elsif local_media['display_url']
              text.gsub!(%r{#{Regexp.quote(local_media['url'])}}, local_media['display_url'])
            end
          end

          url = local_media['media_url_https'] || local_media['media_url']
          next if url.blank?

          result = download_file(url)
          if !result.success? || !result.body
            Rails.logger.error "Unable for download image from twitter (#{url}): #{result.code}"
            next
          end

          attachment = {
            filename: url.sub(%r{^.*/(.+?)$}, '\1'),
            content:  result.body,

          }
          attachments.push attachment
        end
      end

      in_reply_to = item['in_reply_to_status_id']

      twitter_preferences = {
        mention_ids:         mention_ids,
        geo:                 item['geo'],
        retweeted:           item['retweeted'],
        possibly_sensitive:  item['possibly_sensitive'],
        in_reply_to_user_id: item['in_reply_to_user_id'],
        place:               item['place'],
        retweet_count:       item['retweet_count'],
        source:              item['source'],
        favorited:           item['favorited'],
        truncated:           item['truncated'],
      }

      article_preferences = {
        twitter: self.class.preferences_cleanup(twitter_preferences),
        links:   [
          {
            url:    STATUS_URL_TEMPLATE % item['id'],
            target: '_blank',
            name:   'on Twitter',
          },
        ],
      }

    else
      raise "Unknown tweet type '#{item.class}'"
    end

    UserInfo.current_user_id = user.id

    # set ticket state to open if not new
    ticket_state = get_state(channel, item, ticket)
    if ticket_state.name != ticket.state.name
      ticket.state = ticket_state
      ticket.save!
    end

    article = Ticket::Article.create!(
      from:        from,
      to:          to,
      body:        text,
      message_id:  message_id,
      ticket_id:   ticket.id,
      in_reply_to: in_reply_to,
      type_id:     Ticket::Article::Type.find_by(name: article_type).id,
      sender_id:   Ticket::Article::Sender.find_by(name: 'Customer').id,
      internal:    false,
      preferences: self.class.preferences_cleanup(article_preferences),
    )

    attachments.each do |attachment|
      Store.add(
        object:      'Ticket::Article',
        o_id:        article.id,
        data:        attachment[:content],
        filename:    attachment[:filename],
        preferences: {},
      )
    end

  end

  def to_article(tweet, user, ticket, channel)

    Rails.logger.debug { 'Create article from tweet...' }
    Rails.logger.debug { tweet.inspect }
    Rails.logger.debug { user.inspect }
    Rails.logger.debug { ticket.inspect }

    # import tweet
    to = nil
    raise "Unknown tweet type '#{tweet.class}'" if tweet.class != Twitter::Tweet

    article_type = 'twitter status'
    from = "@#{tweet.user.screen_name}"
    mention_ids = []
    tweet.user_mentions&.each do |local_user|
      if to
        to += ', '
      else
        to = ''
      end
      to += "@#{local_user.screen_name}"
      mention_ids.push local_user.id
    end
    in_reply_to = tweet.in_reply_to_status_id

    twitter_preferences = {
      mention_ids:         mention_ids,
      geo:                 tweet.geo,
      retweeted:           tweet.retweeted?,
      possibly_sensitive:  tweet.possibly_sensitive?,
      in_reply_to_user_id: tweet.in_reply_to_user_id,
      place:               tweet.place,
      retweet_count:       tweet.retweet_count,
      source:              tweet.source,
      favorited:           tweet.favorited?,
      truncated:           tweet.truncated?,
    }

    UserInfo.current_user_id = user.id

    # set ticket state to open if not new
    ticket_state = get_state(channel, tweet, ticket)
    if ticket_state.name != ticket.state.name
      ticket.state = ticket_state
      ticket.save!
    end

    article_preferences = {
      twitter: self.class.preferences_cleanup(twitter_preferences),
      links:   [
        {
          url:    STATUS_URL_TEMPLATE % tweet.id,
          target: '_blank',
          name:   'on Twitter',
        },
      ],
    }

    Ticket::Article.create!(
      from:        from,
      to:          to,
      body:        tweet.text,
      message_id:  tweet.id,
      ticket_id:   ticket.id,
      in_reply_to: in_reply_to,
      type_id:     Ticket::Article::Type.find_by(name: article_type).id,
      sender_id:   Ticket::Article::Sender.find_by(name: 'Customer').id,
      internal:    false,
      preferences: self.class.preferences_cleanup(article_preferences),
    )
  end

  def to_group(tweet, group_id, channel)

    Rails.logger.debug { 'import tweet' }

    ticket = nil
    Transaction.execute(reset_user_id: true) do

      # check if parent exists
      user = to_user(tweet)
      raise "Unknown tweet type '#{tweet.class}'" if tweet.class != Twitter::Tweet

      if tweet.in_reply_to_status_id && tweet.in_reply_to_status_id.to_s != ''
        existing_article = Ticket::Article.find_by(message_id: tweet.in_reply_to_status_id)
        if existing_article
          ticket = existing_article.ticket
        else
          begin
            parent_tweet = @client.status(tweet.in_reply_to_status_id)
            ticket = to_group(parent_tweet, group_id, channel)
          rescue Twitter::Error::NotFound, Twitter::Error::Forbidden => e
            # just ignore if tweet has already gone
            Rails.logger.info "Can't import tweet (#{tweet.in_reply_to_status_id}), #{e.message}"
          end
        end
      end
      if !ticket
        ticket = to_ticket(tweet, user, group_id, channel)
      end
      to_article(tweet, user, ticket, channel)
    end

    ticket
  end

=begin

create a tweet or direct message from an article

=end

  def from_article(article)

    tweet = nil
    case article[:type]
    when 'twitter direct-message'

      Rails.logger.debug { "Create twitter direct message from article to '#{article[:to]}'..." }

      #      tweet = @client.create_direct_message(
      #        article[:to],
      #        article[:body],
      #        {}
      #      )
      article[:to].delete!('@')
      authorization = Authorization.find_by(provider: 'twitter', username: article[:to])
      raise "Unable to lookup user_id for @#{article[:to]}" if !authorization

      data = {
        event: {
          type:           'message_create',
          message_create: {
            target:       {
              recipient_id: authorization.uid,
            },
            message_data: {
              text: article[:body],
            }
          }
        }
      }

      tweet = Twitter::REST::Request.new(@client, :json_post, '/1.1/direct_messages/events/new.json', data).perform

    when 'twitter status'

      Rails.logger.debug { 'Create tweet from article...' }

      # rubocop:disable Style/AsciiComments
      # workaround for https://github.com/sferik/twitter/issues/677
      # https://github.com/zammad/zammad/issues/2873 - unable to post
      # tweets with * - replace `*` with the wide-asterisk `＊`.
      # rubocop:enable Style/AsciiComments
      article[:body].tr!('*', '＊') if article[:body].present?
      tweet = @client.update(
        article[:body],
        {
          in_reply_to_status_id: article[:in_reply_to]
        }
      )
    else
      raise "Can't handle unknown twitter article type '#{article[:type]}'."
    end

    Rails.logger.debug { tweet.inspect }
    tweet
  end

  def get_state(channel, tweet, ticket = nil)

    user_id = if tweet.is_a?(Hash)
                if tweet['user'] && tweet['user']['id']
                  tweet['user']['id']
                else
                  tweet['message_create']['sender_id']
                end
              else
                user(tweet).id
              end

    # no changes in post is from page user it self
    if channel.options[:user][:id].to_s == user_id.to_s
      if !ticket
        return Ticket::State.find_by(name: 'closed')
      end

      return ticket.state
    end

    state = Ticket::State.find_by(default_create: true)
    return state if !ticket
    return ticket.state if ticket.state_id == state.id

    Ticket::State.find_by(default_follow_up: true)
  end

  def tweet_limit_reached(tweet, factor = 1)
    max_count = 120
    max_count = max_count * factor
    type_id = Ticket::Article::Type.lookup(name: 'twitter status').id
    created_at = Time.zone.now - 15.minutes
    created_count = Ticket::Article.where('created_at > ? AND type_id = ?', created_at, type_id).count
    if created_count > max_count
      Rails.logger.info "Tweet limit of #{created_count}/#{max_count} reached, ignored tweed id (#{tweet.id})"
      return true
    end
    false
  end

=begin

  replace Twitter::Place and Twitter::Geo as hash and replace Twitter::NullObject with nil

  preferences = TwitterSync.preferences_cleanup(
    twitter: twitter_preferences,
    links: [
      {
        url: 'https://twitter.com/_/status/123',
        target: '_blank',
        name: 'on Twitter',
      },
    ],
  )

or

  preferences = {
    twitter: TwitterSync.preferences_cleanup(twitter_preferences),
    links: [
      {
        url: 'https://twitter.com/_/status/123',
        target: '_blank',
        name: 'on Twitter',
      },
    ],
  }

=end

  def self.preferences_cleanup(preferences)

    # replace Twitter::NullObject with nill to prevent elasticsearch index issue
    preferences.each do |key, value|

      if value.instance_of?(Twitter::Place) || value.instance_of?(Twitter::Geo)
        preferences[key] = value.to_h
        next
      end
      if value.instance_of?(Twitter::NullObject)
        preferences[key] = nil
        next
      end

      next if !value.is_a?(Hash)

      value.each do |sub_key, sub_level|
        if sub_level.instance_of?(NilClass)
          value[sub_key] = nil
          next
        end
        if sub_level.instance_of?(Twitter::Place) || sub_level.instance_of?(Twitter::Geo)
          value[sub_key] = sub_level.to_h
          next
        end
        next if sub_level.class != Twitter::NullObject

        value[sub_key] = nil
      end
    end

    if preferences[:twitter]
      if preferences[:twitter][:geo].blank?
        preferences[:twitter][:geo] = {}
      end
      if preferences[:twitter][:place].blank?
        preferences[:twitter][:place] = {}
      end
    else
      if preferences[:geo].blank?
        preferences[:geo] = {}
      end
      if preferences[:place].blank?
        preferences[:place] = {}
      end
    end

    preferences
  end

=begin

check if tweet is from local sender

  client = TwitterSync.new
  client.locale_sender?(tweet)

=end

  def locale_sender?(tweet)
    tweet_user = user(tweet)
    Channel.where(area: 'Twitter::Account').each do |local_channel|
      next if !local_channel.options
      next if !local_channel.options[:user]
      next if !local_channel.options[:user][:id]
      next if local_channel.options[:user][:id].to_s != tweet_user.id.to_s

      Rails.logger.debug { "Tweet is sent by local account with user id #{tweet_user.id} and tweet.id #{tweet.id}" }
      return true
    end
    false
  end

=begin

process webhook messages from twitter

  client = TwitterSync.new
  client.process_webhook(channel)

=end

  def process_webhook(channel)
    Rails.logger.debug { 'import tweet' }
    ticket = nil
    if @payload['direct_message_events'].present? && channel.options[:sync][:direct_messages][:group_id].present?
      @payload['direct_message_events'].each do |item|
        next if item['type'] != 'message_create'

        next if Ticket::Article.exists?(message_id: item['id'])

        user = to_user_webhook(item['message_create']['sender_id'])
        ticket = to_ticket(item, user, channel.options[:sync][:direct_messages][:group_id], channel)
        to_article_webhook(item, user, ticket, channel)
      end
    end

    if @payload['tweet_create_events'].present?
      @payload['tweet_create_events'].each do |item|
        next if Ticket::Article.exists?(message_id: item['id'])
        next if item.key?('retweeted_status') && !channel.options.dig('sync', 'track_retweets')

        # check if it's mention
        group_id = nil
        if channel.options[:sync][:mentions][:group_id].present? && item['entities']['user_mentions']
          item['entities']['user_mentions'].each do |local_user|
            next if channel.options[:user][:id].to_s != local_user['id'].to_s

            group_id = channel.options[:sync][:mentions][:group_id]
            break
          end
        end

        # check if it's search term
        if !group_id && channel.options[:sync][:search].present?
          channel.options[:sync][:search].each do |local_search|
            next if local_search[:term].blank?
            next if local_search[:group_id].blank?
            next if !item['text'].match?(%r{#{Regexp.quote(local_search[:term])}}i)

            group_id = local_search[:group_id]
            break
          end
        end

        next if !group_id

        user = to_user_webhook(item['user']['id'], item['user'])
        if item['in_reply_to_status_id'].present?
          existing_article = Ticket::Article.find_by(message_id: item['in_reply_to_status_id'])
          if existing_article
            ticket = existing_article.ticket
          else
            begin
              parent_tweet = @client.status(item['in_reply_to_status_id'])
              ticket = to_group(parent_tweet, group_id, channel)
            rescue Twitter::Error::NotFound, Twitter::Error::Forbidden => e
              # just ignore if tweet has already gone
              Rails.logger.info "Can't import tweet (#{item['in_reply_to_status_id']}), #{e.message}"
            end
          end
        end
        if !ticket
          ticket = to_ticket(item, user, group_id, channel)
        end
        to_article_webhook(item, user, ticket, channel)
      end
    end

    ticket
  end

  def get_app_webhook(app_id)
    return {} if !@payload['apps']
    return {} if !@payload['apps'][app_id]

    @payload['apps'][app_id]
  end

  def to_user_webhook_data(user_id)
    if @payload['user'] && @payload['user']['id'].to_s == user_id.to_s
      return @payload['user']
    end
    raise 'no users in payload' if !@payload['users']
    raise 'no users in payload' if !@payload['users'][user_id]

    @payload['users'][user_id]
  end

=begin

download public media file from twitter

  client = TwitterSync.new
  result = client.download_file(url)

  result.body

=end

  def download_file(url)
    UserAgent.get(
      url,
      {},
      {
        open_timeout: 20,
        read_timeout: 40,
      },
    )
  end

  def to_user_webhook(user_id, payload_user = nil)
    user_payload = if payload_user && payload_user['id'].to_s == user_id.to_s
                     payload_user
                   else
                     to_user_webhook_data(user_id)
                   end

    auth = Authorization.find_by(uid: user_payload['id'], provider: 'twitter')

    # create or update user
    user_data = {
      image_source: user_payload['profile_image_url'],
    }
    if auth
      user = User.find(auth.user_id)
      map = {
        note:    'description',
        web:     'url',
        address: 'location',
      }

      # ignore if value is already set
      map.each do |target, source|
        next if user[target].present?

        new_value = user_payload[source].to_s
        next if new_value.blank?

        user_data[target] = new_value
      end
      user.update!(user_data)
    else
      user_data[:login]     = user_payload['screen_name']
      user_data[:firstname] = user_payload['name']
      user_data[:web]       = user_payload['url']
      user_data[:note]      = user_payload['description']
      user_data[:address]   = user_payload['location']
      user_data[:active]    = true
      user_data[:role_ids]  = Role.signup_role_ids

      user = User.create!(user_data)
    end

    if user_data[:image_source].present?
      avatar = Avatar.add(
        object:        'User',
        o_id:          user.id,
        url:           user_data[:image_source],
        source:        'twitter',
        deletable:     true,
        updated_by_id: user.id,
        created_by_id: user.id,
      )

      # update user link
      if avatar && user.image != avatar.store_hash
        user.image = avatar.store_hash
        user.save
      end
    end

    # create or update authorization
    auth_data = {
      uid:      user_payload['id'],
      username: user_payload['screen_name'],
      user_id:  user.id,
      provider: 'twitter'
    }
    if auth
      auth.update!(auth_data)
    else
      Authorization.create!(auth_data)
    end

    user
  end

=begin

get the user of current twitter client

  client = TwitterSync.new
  user_hash = client.who_am_i

=end

  def who_am_i
    @client.user
  end

=begin

request a new webhook verification request from twitter

  client = TwitterSync.new
  webhook_request_verification(webhook_id, env_name, webhook_url)

=end

  def webhook_request_verification(webhook_id, env_name, webhook_url)

    Twitter::REST::Request.new(@client, :put, "/1.1/account_activity/all/#{env_name}/webhooks/#{webhook_id}.json", {}).perform
  rescue => e
    raise "Webhook registered but not valid (#{webhook_url}). Unable to set webhook to valid: #{e.message}"

  end

=begin

get webhooks by env_name

  client = TwitterSync.new
  webhooks = webhooks_by_env_name(env_name)

=end

  def webhooks_by_env_name(env_name)
    Twitter::REST::Request.new(@client, :get, "/1.1/account_activity/all/#{env_name}/webhooks.json", {}).perform
  end

=begin

get all webhooks

  client = TwitterSync.new
  webhooks = webhooks(env_name)

=end

  def webhooks
    Twitter::REST::Request.new(@client, :get, '/1.1/account_activity/all/webhooks.json', {}).perform
  end

=begin

delete a webhooks

  client = TwitterSync.new
  webhook_delete(webhook_id, env_name)

=end

  def webhook_delete(webhook_id, env_name)
    Twitter::REST::Request.new(@client, :delete, "/1.1/account_activity/all/#{env_name}/webhooks/#{webhook_id}.json", {}).perform
  end

=begin

register a new webhooks at twitter

  client = TwitterSync.new
  webhook_register(env_name, webhook_url)

=end

  def webhook_register(env_name, webhook_url)
    options = {
      url: webhook_url,
    }
    begin
      response = Twitter::REST::Request.new(@client, :post, "/1.1/account_activity/all/#{env_name}/webhooks.json", options).perform
    rescue => e
      message = "Unable to register webhook: #{e.message}"
      if %r{http://}.match?(webhook_url)
        message += ' Only https webhooks possible to register.'
      elsif webhooks.count.positive?
        message += " Already #{webhooks.count} webhooks registered. Maybe you need to delete one first."
      end
      raise message
    end
    response
  end

=begin

subscribe a user to a webhooks at twitter

  client = TwitterSync.new
  webhook_subscribe(env_name)

=end

  def webhook_subscribe(env_name)

    Twitter::REST::Request.new(@client, :post, "/1.1/account_activity/all/#{env_name}/subscriptions.json", {}).perform
  rescue => e
    raise "Unable to subscriptions with via webhook: #{e.message}"

  end

end
