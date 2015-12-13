# Copyright (C) 2012-2015 Zammad Foundation, http://zammad-foundation.org/

require 'twitter'

class Tweet

  attr_accessor :client

  def initialize(auth)

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

  def user(tweet)

    if tweet.class == Twitter::DirectMessage
      Rails.logger.error "Twitter sender for dm (#{tweet.id}): found"
      Rails.logger.debug tweet.sender.inspect
      return tweet.sender
    elsif tweet.class == Twitter::Tweet
      Rails.logger.error "Twitter sender for tweet (#{tweet.id}): found"
      Rails.logger.debug tweet.user.inspect
      return tweet.user
    else
      fail "Unknown tweet type '#{tweet.class}'"
    end

  end

  def to_user(tweet)

    Rails.logger.debug 'Create user from tweet...'
    Rails.logger.debug tweet.inspect

    # do tweet_user lookup
    tweet_user = user(tweet)

    auth = Authorization.find_by(uid: tweet_user.id, provider: 'twitter')

    # create or update user
    user_data = {
      login:        tweet_user.screen_name,
      image_source: tweet_user.profile_image_url.to_s,
    }
    if auth
      user = User.find(auth.user_id)
      if (!user_data[:note] || user_data[:note].empty?) && tweet_user.description
        user_data[:note] = tweet_user.description
      end
      user.update_attributes(user_data)
    else
      user_data[:firstname] = tweet_user.name
      user_data[:note] = tweet_user.description
      user_data[:active] = true
      user_data[:roles] = Role.where(name: 'Customer')
      user = User.create(user_data)
    end

    # create or update authorization
    auth_data = {
      uid:      tweet_user.id,
      username: tweet_user.screen_name,
      user_id:  user.id,
      provider: 'twitter'
    }
    if auth
      auth.update_attributes(auth_data)
    else
      Authorization.create(auth_data)
    end

    UserInfo.current_user_id = user.id

    user
  end

  def to_ticket(tweet, user, group_id)

    Rails.logger.debug 'Create ticket from tweet...'
    Rails.logger.debug tweet.inspect
    Rails.logger.debug user.inspect
    Rails.logger.debug group_id.inspect

    if tweet.class == Twitter::DirectMessage
      article = Ticket::Article.find_by(
        from:    tweet.sender.screen_name,
        type_id: Ticket::Article::Type.find_by(name: 'twitter direct-message').id,
      )
      if article
        ticket = Ticket.find_by(
          id:          article.ticket_id,
          customer_id: user.id,
          state:       Ticket::State.where.not(
            state_type_id: Ticket::StateType.where(
              name: %w(closed merged removed),
            )
          )
        )
        return ticket if ticket
      end
    end

    Ticket.create(
      customer_id: user.id,
      title:       "#{tweet.text[0, 37]}...",
      group_id:    group_id,
      state_id:    Ticket::State.find_by(name: 'new').id,
      priority_id: Ticket::Priority.find_by(name: '2 normal').id,
    )
  end

  def to_article(tweet, user, ticket)

    Rails.logger.debug 'Create article from tweet...'
    Rails.logger.debug tweet.inspect
    Rails.logger.debug user.inspect
    Rails.logger.debug ticket.inspect

    # set ticket state to open if not new
    if ticket.state.name != 'new'
      ticket.state = Ticket::State.find_by(name: 'open')
      ticket.save
    end

    # import tweet
    to = nil
    from = nil
    article_type = nil
    in_reply_to = nil
    if tweet.class == Twitter::DirectMessage
      article_type = 'twitter direct-message'
      to = tweet.recipient.screen_name
      from = tweet.sender.screen_name
    elsif tweet.class == Twitter::Tweet
      article_type = 'twitter status'
      from = tweet.in_reply_to_screen_name
      in_reply_to = tweet.in_reply_to_status_id
    else
      fail "Unknown tweet type '#{tweet.class}'"
    end

    Ticket::Article.create(
      from:        from,
      to:          to,
      body:        tweet.text,
      message_id:  tweet.id,
      ticket_id:   ticket.id,
      in_reply_to: in_reply_to,
      type_id:     Ticket::Article::Type.find_by(name: article_type).id,
      sender_id:   Ticket::Article::Sender.find_by(name: 'Customer').id,
      internal:    false,
    )
  end

  def to_group(tweet, group_id)

    Rails.logger.debug 'import tweet'

    ticket = nil
    # use transaction
    ActiveRecord::Base.transaction do

      UserInfo.current_user_id = 1

      # check if parent exists
      user = to_user(tweet)
      if tweet.class == Twitter::DirectMessage
        ticket = to_ticket(tweet, user, group_id)
        to_article(tweet, user, ticket)
      elsif tweet.class == Twitter::Tweet
        if tweet.in_reply_to_status_id
          existing_article = Ticket::Article.find_by(message_id: tweet.in_reply_to_status_id)
          if existing_article
            ticket = existing_article.ticket
          else
            parent_tweet = @client.status(tweet.in_reply_to_status_id)
            ticket       = to_group(parent_tweet, group_id)
          end
        else
          ticket = to_ticket(tweet, user, group_id)
        end
        to_article(tweet, user, ticket)
      else
        fail "Unknown tweet type '#{tweet.class}'"
      end

      # execute ticket events
      Observer::Ticket::Notification.transaction
    end

    ticket
  end

  def from_article(article)

    tweet = nil
    if article[:type] == 'twitter direct-message'

      Rails.logger.debug "Create twitter direct message from article to '#{article[:to]}'..."

      tweet = @client.create_direct_message(
        article[:to],
        article[:body],
        {}
      )
    elsif article[:type] == 'twitter status'

      Rails.logger.debug 'Create tweet from article...'

      tweet = @client.update(
        article[:body],
        {
          in_reply_to_status_id: article[:in_reply_to]
        }
      )
    else
      fail "Can't handle unknown twitter article type '#{article[:type]}'."
    end

    Rails.logger.debug tweet.inspect
    tweet
  end

end
