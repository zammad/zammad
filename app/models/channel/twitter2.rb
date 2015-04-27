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
    if @client
      @client = nil
    end
  end

  def fetch (channel)

    puts "fetching tweets (oauth_token#{channel[:options][:oauth_token]})"
    @client = connect(channel)

    # search results
    if channel[:options][:search]
      channel[:options][:search].each { |search|
        puts " - searching for #{search[:item]}"
        tweets = []
        @client.search( search[:item], :count => 50, :result_type => 'recent' ).collect do |tweet|
          tweets.push tweet
        end
        @article_type = 'twitter status'
        fetch_loop( tweets, channel, search[:group] )
      }
    end

    # mentions
    if channel[:options][:mentions]
      puts ' - searching for mentions'
      tweets = @client.mentions_timeline
      @article_type = 'twitter status'
      fetch_loop( tweets, channel, channel[:options][:mentions][:group] )
    end

    # direct messages
    if channel[:options][:direct_messages]
      puts ' - searching for direct_messages'
      tweets = @client.direct_messages
      @article_type = 'twitter direct-message'
      fetch_loop( tweets, channel, channel[:options][:direct_messages][:group] )
    end
    puts 'done'
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
      puts 'UNKNOWN: ' + result_class.to_s
    end

    # find tweets
    all_tweets.each do |tweet|

      # check if tweet is already imported
      article = Ticket::Article.where( :message_id => tweet.id.to_s ).first

      # check if sender already exists
      next if article

      # use transaction
      ActiveRecord::Base.transaction do

        # reset current_user
        UserInfo.current_user_id = 1

        puts 'import tweet'
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
        puts 'Exception: twitter: ' + e.inspect
        return
      end
    end

    # check if parent exists
    user = nil, ticket = nil, article = nil
    if tweet.respond_to?('in_reply_to_status_id') && tweet.in_reply_to_status_id && tweet.in_reply_to_status_id.to_s != ''
      puts 'import in_reply_tweet ' + tweet.in_reply_to_status_id.to_s
      tweet_sub = @client.status( tweet.in_reply_to_status_id )
      #        puts tweet_sub.inspect
      (user, ticket, article) = fetch_import(tweet_sub, channel, group)
    end

    # create stuff
    user = fetch_user_create(tweet, sender)
    if !ticket
      puts 'create new ticket...'
      ticket = fetch_ticket_create(user, tweet, sender, channel, group)
    end
    article = fetch_article_create(user, ticket, tweet, sender)
    return user, ticket, article
  end

  def fetch_user_create(tweet, sender)
    # create sender in db
    #    puts tweet.inspect
    #    user = User.where( :login => tweet.sender.screen_name ).first
    auth = Authorization.where( :uid => sender.id, :provider => 'twitter' ).first
    user = nil
    if auth
      puts 'user_id', auth.user_id
      user = User.where( :id => auth.user_id ).first
    end
    if !user
      puts 'create user...'
      roles = Role.where( :name => 'Customer' )
      user = User.create(
        :login          => sender.screen_name,
        :firstname      => sender.name,
        :lastname       => '',
        :email          => '',
        :password       => '',
        :image_source   => sender.profile_image_url.to_s,
        :note           => sender.description,
        :active         => true,
        :roles          => roles,
        :updated_by_id  => 1,
        :created_by_id  => 1
      )
      puts 'autentication create...'
      authentication = Authorization.create(
        :uid      => sender.id,
        :username => sender.screen_name,
        :user_id  => user.id,
        :provider => 'twitter'
      )
    else
      puts 'user exists'#, user.inspect
    end

    # set current user
    UserInfo.current_user_id = user.id

    return user
  end

  def fetch_ticket_create(user, tweet, sender, channel, group)

    #    puts '+++++++++++++++++++++++++++' + tweet.inspect
    # check if ticket exists
    if tweet.respond_to?('in_reply_to_status_id') && tweet.in_reply_to_status_id && tweet.in_reply_to_status_id.to_s != ''
      puts 'tweet.in_reply_to_status_id found: ' + tweet.in_reply_to_status_id.to_s
      article = Ticket::Article.where( :message_id => tweet.in_reply_to_status_id.to_s ).first
      if article
        puts 'article with id found tweet.in_reply_to_status_id found: ' + tweet.in_reply_to_status_id.to_s
        return article.ticket
      end
    end

    # find if record already exists
    article = Ticket::Article.where( :message_id => tweet.id.to_s ).first
    if article
      return article.ticket
    end

    ticket = nil
    if @article_type == 'twitter direct-message'
      ticket = Ticket.where( :customer_id => user.id ).first
      if ticket
        state_type = Ticket::StateType.where( ticket.state.state_type_id )
        if state_type.name == 'closed' || state_type.name == 'closed'
          ticket = nil
        end
      end
    end
    if !ticket
      group = Group.where( :name => group ).first
      group_id = 1
      if group
        group_id = group.id
      end
      state = Ticket::State.where( :name => 'new' ).first
      state_id = 1
      if state
        state_id = state.id
      end
      priority = Ticket::Priority.where( :name => '2 normal' ).first
      priority_id = 1
      if priority
        priority_id = priority.id
      end
      ticket = Ticket.create(
        :group_id    => group_id,
        :customer_id => user.id,
        :title       => tweet.text[0,40],
        :state_id    => state_id,
        :priority_id => priority_id,
      )
    end

    ticket
  end

  def fetch_article_create( user, ticket, tweet, sender )

    # find if record already exists
    article = Ticket::Article.where( :message_id => tweet.id.to_s ).first
    return article if article

    # set ticket state to open if not new
    if ticket.state.name != 'new'
      ticket.state = Ticket::State.where( :name => 'open' ).first
      ticket.save
    end

    # import tweet
    to = nil
    if tweet.respond_to?('recipient')
      to = tweet.recipient.name
    end

    article = Ticket::Article.create(
      :ticket_id  => ticket.id,
      :type_id    => Ticket::Article::Type.where( :name => @article_type ).first.id,
      :sender_id  => Ticket::Article::Sender.where( :name => 'Customer' ).first.id,
      :body       => tweet.text,
      :from       => sender.name,
      :to         => to,
      :message_id => tweet.id,
      :internal   => false,
    )

  end

  def send(attr, notification = false)
    #    logger.debug('tweeeeettttt!!!!!!')
    channel = Channel.where( :area => 'Twitter::Inbound', :active => true ).first

    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = channel[:options][:consumer_key]
      config.consumer_secret     = channel[:options][:consumer_secret]
      config.access_token        = channel[:options][:oauth_token]
      config.access_token_secret = channel[:options][:oauth_token_secret]
    end
    if attr[:type] == 'twitter direct-message'
      puts 'to:' + attr[:to].to_s
      dm = client.create_direct_message(
        attr[:to].to_s,
        attr[:body].to_s,
        {}
      )
      #      puts dm.inspect
      return dm
    end

    if attr[:type] == 'twitter status'
      message = client.update(
        attr[:body].to_s,
        {
          :in_reply_to_status_id => attr[:in_reply_to]
        }
      )
      #      puts message.inspect
      return message
    end

  end
end
