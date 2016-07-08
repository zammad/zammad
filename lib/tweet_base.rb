# Copyright (C) 2012-2015 Zammad Foundation, http://zammad-foundation.org/

require 'twitter'
load 'lib/http/uri.rb'

class TweetBase

  attr_accessor :client

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
      raise "Unknown tweet type '#{tweet.class}'"
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
      map.each { |target, source|
        next if user[target] && !user[target].empty?
        new_value = tweet_user.send(source).to_s
        next if !new_value || new_value.empty?
        user_data[target] = new_value
      }
      user.update_attributes(user_data)
    else
      user_data[:login]     = tweet_user.screen_name
      user_data[:firstname] = tweet_user.name
      user_data[:web]       = tweet_user.website.to_s
      user_data[:note]      = tweet_user.description
      user_data[:address]   = tweet_user.location
      user_data[:active]    = true
      user_data[:roles]     = Role.where(name: 'Customer')

      user = User.create(user_data)
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
      auth.update_attributes(auth_data)
    else
      Authorization.create(auth_data)
    end

    user
  end

  def to_ticket(tweet, user, group_id, channel)
    UserInfo.current_user_id = user.id

    Rails.logger.debug 'Create ticket from tweet...'
    Rails.logger.debug tweet.inspect
    Rails.logger.debug user.inspect
    Rails.logger.debug group_id.inspect

    if tweet.class == Twitter::DirectMessage
      ticket = Ticket.find_by(
        create_article_type: Ticket::Article::Type.lookup(name: 'twitter direct-message'),
        customer_id:         user.id,
        state:               Ticket::State.where.not(
          state_type_id: Ticket::StateType.where(
            name: %w(closed merged removed),
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

    Ticket.create(
      customer_id: user.id,
      title:       title,
      group_id:    group_id,
      state:       Ticket::State.find_by(name: 'new'),
      priority:    Ticket::Priority.find_by(name: '2 normal'),
      preferences: {
        channel_id: channel.id,
        channel_screen_name: channel.options['user']['screen_name'],
      },
    )
  end

  def to_article(tweet, user, ticket)

    Rails.logger.debug 'Create article from tweet...'
    Rails.logger.debug tweet.inspect
    Rails.logger.debug user.inspect
    Rails.logger.debug ticket.inspect

    # import tweet
    to = nil
    from = nil
    article_type = nil
    in_reply_to = nil
    if tweet.class == Twitter::DirectMessage
      article_type = 'twitter direct-message'
      to = "@#{tweet.recipient.screen_name}"
      from = "@#{tweet.sender.screen_name}"
    elsif tweet.class == Twitter::Tweet
      article_type = 'twitter status'
      from = "@#{tweet.user.screen_name}"
      if tweet.user_mentions
        tweet.user_mentions.each { |local_user|
          if !to
            to = ''
          else
            to + ', '
          end
          to += "@#{local_user.screen_name}"
        }
      end
      in_reply_to = tweet.in_reply_to_status_id
    else
      raise "Unknown tweet type '#{tweet.class}'"
    end

    UserInfo.current_user_id = user.id

    # set ticket state to open if not new
    if ticket.state.name != 'new'
      ticket.state = Ticket::State.find_by(name: 'open')
      ticket.save
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

  def to_group(tweet, group_id, channel)

    Rails.logger.debug 'import tweet'

    ticket = nil
    # use transaction
    if @connection_type == 'stream'
      ActiveRecord::Base.connection.reconnect!

      # if sender is a system account, wait until twitter message id is stored
      # on article to prevent two (own created & twitter created) articles
      tweet_user = user(tweet)
      Channel.where(area: 'Twitter::Account').each { |local_channel|
        next if !local_channel.options
        next if !local_channel.options[:user]
        next if !local_channel.options[:user][:id]
        next if local_channel.options[:user][:id].to_s != tweet_user.id.to_s
        sleep 5

        # return if tweet already exists (send via system)
        if Ticket::Article.find_by(message_id: tweet.id)
          Rails.logger.debug "Do not import tweet.id #{tweet.id}, article already exists"
          return nil
        end
      }
    end
    ActiveRecord::Base.transaction do

      UserInfo.current_user_id = 1

      # check if parent exists
      user = to_user(tweet)
      if tweet.class == Twitter::DirectMessage
        ticket = to_ticket(tweet, user, group_id, channel)
        to_article(tweet, user, ticket)
      elsif tweet.class == Twitter::Tweet
        if tweet.in_reply_to_status_id && tweet.in_reply_to_status_id.to_s != ''
          existing_article = Ticket::Article.find_by(message_id: tweet.in_reply_to_status_id)
          if existing_article
            ticket = existing_article.ticket
          else
            begin
              parent_tweet = @client.status(tweet.in_reply_to_status_id)
              ticket       = to_group(parent_tweet, group_id, channel)
            rescue Twitter::Error::NotFound
              # just ignore if tweet has already gone
              Rails.logger.info "Can't import tweet (#{tweet.in_reply_to_status_id}), tweet not found"
            end
          end
        end
        if !ticket
          ticket = to_ticket(tweet, user, group_id, channel)
        end
        to_article(tweet, user, ticket)
      else
        raise "Unknown tweet type '#{tweet.class}'"
      end

      # execute object transaction
      Observer::Transaction.commit
    end

    if @connection_type == 'stream'
      ActiveRecord::Base.connection.close
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
      raise "Can't handle unknown twitter article type '#{article[:type]}'."
    end

    Rails.logger.debug tweet.inspect
    tweet
  end

  def tweet_limit_reached(tweet)
    max_count = 60
    if @connection_type == 'stream'
      max_count = 15
    end
    type_id = Ticket::Article::Type.lookup(name: 'twitter status').id
    created_at = Time.zone.now - 15.minutes
    if Ticket::Article.where('created_at > ? AND type_id = ?', created_at, type_id).count > max_count
      Rails.logger.info "Tweet limit reached, ignored tweed id (#{tweet.id})"
      return true
    end
    false
  end

  def direct_message_limit_reached(tweet)
    max_count = 100
    if @connection_type == 'stream'
      max_count = 40
    end
    type_id = Ticket::Article::Type.lookup(name: 'twitter direct-message').id
    created_at = Time.zone.now - 15.minutes
    if Ticket::Article.where('created_at > ? AND type_id = ?', created_at, type_id).count > max_count
      Rails.logger.info "Tweet direct message limit reached, ignored tweed id (#{tweet.id})"
      return true
    end
    false
  end

end
