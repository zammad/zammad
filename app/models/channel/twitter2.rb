# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

require 'twitter'

class Channel::TWITTER2
  def connect(channel)
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key        = channel[:options][:consumer_key]
      config.consumer_secret     = channel[:options][:consumer_secret]
      config.access_token        = channel[:options][:oauth_token]
      config.access_token_secret = channel[:options][:oauth_token_secret]
    end
  end

  def disconnect

    return if !@client

    @client = nil
  end

  def fetch (channel)

    Rails.logger.info "fetching tweets (oauth_token#{channel[:options][:oauth_token]})"
    @client = connect(channel)

    # search results
    if channel[:options][:search]
      channel[:options][:search].each { |search|
        Rails.logger.info " - searching for #{search[:item]}"
        tweets = []
        @client.search( search[:item], count: 50, result_type: 'recent' ).collect do |tweet|
          tweets.push tweet
        end
        @article_type = 'twitter status'
        fetch_loop( tweets, channel, search[:group] )
      }
    end

    # mentions
    if channel[:options][:mentions]
      Rails.logger.info ' - searching for mentions'
      tweets = @client.mentions_timeline
      @article_type = 'twitter status'
      fetch_loop( tweets, channel, channel[:options][:mentions][:group] )
    end

    # direct messages
    if channel[:options][:direct_messages]
      Rails.logger.info ' - searching for direct_messages'
      tweets = @client.direct_messages
      @article_type = 'twitter direct-message'
      fetch_loop( tweets, channel, channel[:options][:direct_messages][:group] )
    end
    Rails.logger.info 'done'
    disconnect
  end

  def fetch_loop( tweets, channel, group )

    # get all tweets
    all_tweets = []
    result_class = tweets.class
    if result_class.to_s == 'Array'
      all_tweets = tweets
    elsif result_class.to_s == 'Twitter::SearchResults'
      tweets.results.map do |tweet|
        all_tweets.push tweet
      end
    else
      Rails.logger.error 'UNKNOWN: ' + result_class.to_s
    end

    # find tweets
    all_tweets.each do |tweet|

      # check if tweet is already imported
      article = Ticket::Article.find_by( message_id: tweet.id.to_s )

      # check if sender already exists
      next if article

      # use transaction
      ActiveRecord::Base.transaction do

        # reset current_user
        UserInfo.current_user_id = 1

        Rails.logger.info 'import tweet'
        fetch_import( tweet, channel, group )
      end

      # execute ticket events
      Observer::Ticket::Notification.transaction
    end
  end

  def fetch_import(tweet, channel, group)

    # do sender lockup if needed
    sender = nil

    # status (full user data is included)
    if tweet.respond_to?('user')
      sender = tweet.user

    # direct message (full user data is included)
    elsif tweet.respond_to?('sender')
      sender = tweet.sender

    # search (no user data is included, do extra lookup)
    elsif tweet.respond_to?('from_user_id')
      begin
        sender = @client.user(tweet.from_user_id)
      rescue Exception => e
        Rails.logger.error 'Exception: twitter: ' + e.inspect
        return
      end
    end

    # check if parent exists
    user = nil, ticket = nil, article = nil
    if tweet.respond_to?('in_reply_to_status_id') && tweet.in_reply_to_status_id && tweet.in_reply_to_status_id.to_s != ''
      Rails.logger.info 'import in_reply_tweet ' + tweet.in_reply_to_status_id.to_s
      tweet_sub = @client.status( tweet.in_reply_to_status_id )
      #Rails.logger.debug tweet_sub.inspect
      (user, ticket, article) = fetch_import(tweet_sub, channel, group)
    end

    # create stuff
    user = fetch_user_create(tweet, sender)
    if !ticket
      Rails.logger.info 'create new ticket...'
      ticket = fetch_ticket_create(user, tweet, sender, channel, group)
    end
    article = fetch_article_create(user, ticket, tweet, sender)
    [user, ticket, article]
  end

  def fetch_user_create(_tweet, sender)
    # create sender in db
    #    puts tweet.inspect
    #    user = User.where( :login => tweet.sender.screen_name ).first
    auth = Authorization.find_by( uid: sender.id, provider: 'twitter' )
    user = nil
    if auth
      Rails.logger.info 'user_id', auth.user_id
      user = User.find_by( id: auth.user_id )
    end
    if !user
      Rails.logger.info 'create user...'
      roles = Role.where( name: 'Customer' )
      user = User.create(
        login: sender.screen_name,
        firstname: sender.name,
        lastname: '',
        email: '',
        password: '',
        image_source: sender.profile_image_url.to_s,
        note: sender.description,
        active: true,
        roles: roles,
        updated_by_id: 1,
        created_by_id: 1
      )
      Rails.logger.info 'autentication create...'
      authentication = Authorization.create(
        uid: sender.id,
        username: sender.screen_name,
        user_id: user.id,
        provider: 'twitter'
      )
    else
      Rails.logger.info 'user exists'
    end

    # set current user
    UserInfo.current_user_id = user.id

    user
  end

  def fetch_ticket_create(user, tweet, _sender, _channel, group)

    #Rails.logger.info '+++++++++++++++++++++++++++' + tweet.inspect
    # check if ticket exists
    if tweet.respond_to?('in_reply_to_status_id') && tweet.in_reply_to_status_id && tweet.in_reply_to_status_id.to_s != ''
      Rails.logger.info 'tweet.in_reply_to_status_id found: ' + tweet.in_reply_to_status_id.to_s
      article = Ticket::Article.find_by( message_id: tweet.in_reply_to_status_id.to_s )
      if article
        Rails.logger.info 'article with id found tweet.in_reply_to_status_id found: ' + tweet.in_reply_to_status_id.to_s
        return article.ticket
      end
    end

    # find if record already exists
    article = Ticket::Article.find_by( message_id: tweet.id.to_s )
    if article
      return article.ticket
    end

    ticket = nil
    if @article_type == 'twitter direct-message'
      ticket = Ticket.find_by( customer_id: user.id )
      if ticket
        state_type = Ticket::StateType.where( ticket.state.state_type_id )
        if state_type.name == 'closed' || state_type.name == 'closed'
          ticket = nil
        end
      end
    end
    if !ticket
      group = Group.find_by( name: group )
      group_id = 1
      if group
        group_id = group.id
      end
      state = Ticket::State.find_by( name: 'new' )
      state_id = 1
      if state
        state_id = state.id
      end
      priority = Ticket::Priority.find_by( name: '2 normal' )
      priority_id = 1
      if priority
        priority_id = priority.id
      end
      ticket = Ticket.create(
        group_id: group_id,
        customer_id: user.id,
        title: tweet.text[0, 40],
        state_id: state_id,
        priority_id: priority_id,
      )
    end

    ticket
  end

  def fetch_article_create( _user, ticket, tweet, sender )

    # find if record already exists
    article = Ticket::Article.find_by( message_id: tweet.id.to_s )
    return article if article

    # set ticket state to open if not new
    if ticket.state.name != 'new'
      ticket.state = Ticket::State.find_by( name: 'open' )
      ticket.save
    end

    # import tweet
    to = nil
    if tweet.respond_to?('recipient')
      to = tweet.recipient.name
    end

    article = Ticket::Article.create(
      ticket_id: ticket.id,
      type_id: Ticket::Article::Type.find_by( name: @article_type ).id,
      sender_id: Ticket::Article::Sender.find_by( name: 'Customer' ).id,
      body: tweet.text,
      from: sender.name,
      to: to,
      message_id: tweet.id,
      internal: false,
    )

  end

  def send(attr, _notification = false)
    #    Rails.logger.debug('tweeeeettttt!!!!!!')
    channel = Channel.find_by( area: 'Twitter::Inbound', active: true )

    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = channel[:options][:consumer_key]
      config.consumer_secret     = channel[:options][:consumer_secret]
      config.access_token        = channel[:options][:oauth_token]
      config.access_token_secret = channel[:options][:oauth_token_secret]
    end
    if attr[:type] == 'twitter direct-message'
      Rails.logger.info 'to:' + attr[:to].to_s
      dm = client.create_direct_message(
        attr[:to].to_s,
        attr[:body].to_s,
        {}
      )
      # Rails.logger.info dm.inspect
      return dm
    end

    return if attr[:type] != 'twitter status'

    message = client.update(
      attr[:body].to_s,
      {
        in_reply_to_status_id: attr[:in_reply_to]
      }
    )
    # Rails.logger.debug message.inspect
    message
  end
end
