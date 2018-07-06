# Copyright (C) 2012-2015 Zammad Foundation, http://zammad-foundation.org/

require 'http/uri'

class TweetBase

  attr_accessor :client

  def user(tweet)

    if tweet.class == Twitter::DirectMessage
      Rails.logger.debug { "Twitter sender for dm (#{tweet.id}): found" }
      Rails.logger.debug { tweet.sender.inspect }
      tweet.sender
    elsif tweet.class == Twitter::Tweet
      Rails.logger.debug { "Twitter sender for tweet (#{tweet.id}): found" }
      Rails.logger.debug { tweet.user.inspect }
      tweet.user
    else
      raise "Unknown tweet type '#{tweet.class}'"
    end

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
        note: 'description',
        web: 'website',
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
        object: 'User',
        o_id: user.id,
        url: user_data[:image_source],
        source: 'twitter',
        deletable: true,
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

    if tweet.class == Twitter::DirectMessage
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
    title = tweet.text
    if title.length > 80
      title = "#{title[0, 80]}..."
    end

    state = get_state(channel, tweet)

    Ticket.create!(
      customer_id: user.id,
      title:       title,
      group_id:    group_id || Group.first.id,
      state:       state,
      priority:    Ticket::Priority.find_by(name: '2 normal'),
      preferences: {
        channel_id: channel.id,
        channel_screen_name: channel.options['user']['screen_name'],
      },
    )
  end

  def to_article(tweet, user, ticket, channel)

    Rails.logger.debug { 'Create article from tweet...' }
    Rails.logger.debug { tweet.inspect }
    Rails.logger.debug { user.inspect }
    Rails.logger.debug { ticket.inspect }

    # import tweet
    to = nil
    from = nil
    article_type = nil
    in_reply_to = nil
    twitter_preferences = {}
    if tweet.class == Twitter::DirectMessage
      article_type = 'twitter direct-message'
      to = "@#{tweet.recipient.screen_name}"
      from = "@#{tweet.sender.screen_name}"
      twitter_preferences = {
        created_at: tweet.created_at,
        recipient_id: tweet.recipient.id,
        recipient_screen_name: tweet.recipient.screen_name,
        sender_id: tweet.sender.id,
        sender_screen_name: tweet.sender.screen_name,
      }
    elsif tweet.class == Twitter::Tweet
      article_type = 'twitter status'
      from = "@#{tweet.user.screen_name}"
      mention_ids = []
      tweet.user_mentions&.each do |local_user|
        if !to
          to = ''
        else
          to += ', '
        end
        to += "@#{local_user.screen_name}"
        mention_ids.push local_user.id
      end
      in_reply_to = tweet.in_reply_to_status_id

      twitter_preferences = {
        mention_ids: mention_ids,
        geo: tweet.geo,
        retweeted: tweet.retweeted?,
        possibly_sensitive: tweet.possibly_sensitive?,
        in_reply_to_user_id: tweet.in_reply_to_user_id,
        place: tweet.place,
        retweet_count: tweet.retweet_count,
        source: tweet.source,
        favorited: tweet.favorited?,
        truncated: tweet.truncated?,
      }

    else
      raise "Unknown tweet type '#{tweet.class}'"
    end

    UserInfo.current_user_id = user.id

    # set ticket state to open if not new
    ticket_state = get_state(channel, tweet, ticket)
    if ticket_state.name != ticket.state.name
      ticket.state = ticket_state
      ticket.save!
    end

    article_preferences = {
      twitter: twitter_preferences,
      links: [
        {
          url: "https://twitter.com/statuses/#{tweet.id}",
          target: '_blank',
          name: 'on Twitter',
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
      preferences: preferences_cleanup(article_preferences),
    )
  end

  def to_group(tweet, group_id, channel)

    Rails.logger.debug { 'import tweet' }

    # use transaction
    if @connection_type == 'stream'
      ActiveRecord::Base.connection.reconnect!
    end

    ticket = nil
    Transaction.execute(reset_user_id: true) do

      # check if parent exists
      user = to_user(tweet)
      if tweet.class == Twitter::DirectMessage
        ticket = to_ticket(tweet, user, group_id, channel)
        to_article(tweet, user, ticket, channel)
      elsif tweet.class == Twitter::Tweet
        if tweet.in_reply_to_status_id && tweet.in_reply_to_status_id.to_s != ''
          existing_article = Ticket::Article.find_by(message_id: tweet.in_reply_to_status_id)
          if existing_article
            ticket = existing_article.ticket
          else
            begin
              # in case of streaming mode, get parent tweet via REST client
              if @connection_type == 'stream'
                client = TweetRest.new(@auth)
                parent_tweet = client.status(tweet.in_reply_to_status_id)
              else
                parent_tweet = @client.status(tweet.in_reply_to_status_id)
              end
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
      else
        raise "Unknown tweet type '#{tweet.class}'"
      end
    end

    if @connection_type == 'stream'
      ActiveRecord::Base.connection.close
    end
    ticket
  end

  def from_article(article)

    tweet = nil
    if article[:type] == 'twitter direct-message'

      Rails.logger.debug { "Create twitter direct message from article to '#{article[:to]}'..." }

      tweet = @client.create_direct_message(
        article[:to],
        article[:body],
        {}
      )
    elsif article[:type] == 'twitter status'

      Rails.logger.debug { 'Create tweet from article...' }

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

    tweet_user = user(tweet)

    # no changes in post is from page user it self
    if channel.options[:user][:id].to_s == tweet_user.id.to_s
      if !ticket
        return Ticket::State.find_by(name: 'closed') if !ticket
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
    if @connection_type == 'stream'
      max_count = 30
    end
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

  def direct_message_limit_reached(tweet, factor = 1)
    max_count = 100
    if @connection_type == 'stream'
      max_count = 40
    end
    max_count = max_count * factor
    type_id = Ticket::Article::Type.lookup(name: 'twitter direct-message').id
    created_at = Time.zone.now - 15.minutes
    created_count = Ticket::Article.where('created_at > ? AND type_id = ?', created_at, type_id).count
    if created_count > max_count
      Rails.logger.info "Tweet direct message limit reached #{created_count}/#{max_count}, ignored tweed id (#{tweet.id})"
      return true
    end
    false
  end

  def preferences_cleanup(preferences)

    # replace Twitter::NullObject with nill to prevent elasticsearch index issue
    preferences.each_value do |value|
      next if !value.is_a?(Hash)
      value.each do |sub_key, sub_level|
        if sub_level.class == NilClass
          value[sub_key] = nil
          next
        end
        if sub_level.class == Twitter::Place || sub_level.class == Twitter::Geo
          value[sub_key] = sub_level.attrs
          next
        end
        next if sub_level.class != Twitter::NullObject
        value[sub_key] = nil
      end
    end
    preferences
  end

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

end
