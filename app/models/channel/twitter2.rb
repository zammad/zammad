require 'twitter'

class Channel::Twitter2
  include UserInfo

  def connect(channel)
    @client = Twitter::Client.new(
      :consumer_key       => channel[:options][:consumer_key],
      :consumer_secret    => channel[:options][:consumer_secret],
      :oauth_token        => channel[:options][:oauth_token],
      :oauth_token_secret => channel[:options][:oauth_token_secret]
    )
  end

  def fetch (channel)

    puts "fetching tweets (oauth_token#{channel[:options][:oauth_token]})"
    @client = connect(channel)

    # search results
    if channel[:options][:search]
      channel[:options][:search].each { |search|
        puts " - searching for #{search[:item]}"
        tweets = @client.search( search[:item] )
        @article_type = 'twitter status'
        fetch_loop(tweets, channel, search[:group])
      }
    end

    # mentions
    if channel[:options][:mentions]
      puts " - searching for mentions"
      tweets = @client.mentions
      @article_type = 'twitter status'
      fetch_loop(tweets, channel, channel[:options][:mentions][:group])
    end
    
    # direct messages
    if channel[:options][:direct_messages]
      puts " - searching for direct_messages"
      tweets = @client.direct_messages
      @article_type = 'twitter direct-message'
      fetch_loop(tweets, channel, channel[:options][:direct_messages][:group])
    end
    puts 'done'
  end

  def fetch_loop(tweets, channel, group)

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
    if tweet['user']
      sender = tweet['user']

    # direct message (full user data is included)
    elsif tweet['sender']
      sender = tweet['sender']

    # search (no user data is included, do extra lookup)
    elsif tweet['from_user_id']
      begin

        # reconnect for #<Twitter::Error::NotFound: Sorry, that page does not exist> workaround
#        @client = connect(channel)
        sender = @client.user(tweet.from_user_id)
      rescue Exception => e
        puts "Exception: twitter: " + e.inspect
        return
      end
    end

    # check if parent exists
    user = nil, ticket = nil, article = nil
    if tweet['in_reply_to_status_id']
      puts 'import in_reply_tweet ' + tweet.in_reply_to_status_id.to_s
      tweet_sub = @client.status(tweet.in_reply_to_status_id)
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
        :image          => sender.profile_image_url,
        :note           => sender.description,
        :active         => true,
        :roles          => roles,
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
    if tweet['in_reply_to_status_id']
      puts 'tweet.in_reply_to_status_id found: ' + tweet.in_reply_to_status_id
      article = Ticket::Article.where( :message_id => tweet.in_reply_to_status_id.to_s ).first
      if article
        puts 'article with id found tweet.in_reply_to_status_id found: ' + tweet.in_reply_to_status_id
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
        :group_id           => group_id,
        :customer_id        => user.id,
        :title              => tweet.text[0,40],
        :ticket_state_id    => state_id,
        :ticket_priority_id => priority_id,
        :created_by_id      => user.id
      )
    end

    return ticket
  end

  def fetch_article_create(user,ticket,tweet, sender)

    # find if record already exists
    article = Ticket::Article.where( :message_id => tweet.id.to_s ).first
    if article
      return article
    end

    # set ticket state to open if not new
    if ticket.ticket_state.name != 'new'
      ticket.ticket_state = Ticket::State.where( :name => 'open' ).first
      ticket.save
    end

    # import tweet
    to = nil
    if tweet['recipient']
      to = tweet.recipient.name
    end
    article = Ticket::Article.create(
      :created_by_id            => user.id,
      :ticket_id                => ticket.id,
      :ticket_article_type_id   => Ticket::Article::Type.where( :name => @article_type ).first.id,
      :ticket_article_sender_id => Ticket::Article::Sender.where( :name => 'Customer' ).first.id,
      :body                     => tweet.text,
      :from                     => sender.name,
      :to                       => to,
      :message_id               => tweet.id,
      :internal                 => false
    )

  end

  def send(attr, notification = false)
#    logger.debug('tweeeeettttt!!!!!!')
    channel = Channel.where( :area => 'Twitter::Inbound', :active => true ).first

    client = Twitter::Client.new(
      :consumer_key       => channel[:options][:consumer_key],
      :consumer_secret    => channel[:options][:consumer_secret],
      :oauth_token        => channel[:options][:oauth_token],
      :oauth_token_secret => channel[:options][:oauth_token_secret]
    )
    puts 'to:' + atts[:to].to_s
    if atts[:type] == 'twitter direct-message'
      dm = client.direct_message_create(
        atts[:to].to_s,
        atts[:body].to_s,
        options = {}
      )
#      puts dm.inspect
      return dm      
    end

    if atts[:type] == 'twitter status'
      message = client.update(
        atts[:body].to_s,
        options = {
          :in_reply_to_status_id => atts[:in_reply_to]
        }
      )
#      puts message.inspect
      return message
    end

  end
end