require 'twitter'

class Channel::Twitter2
  include UserInfo

#  def fetch(:oauth_token, :oauth_token_secret)
  def fetch (account)

    puts 'fetching tweets'
    @client = Twitter::Client.new(
      :consumer_key       => account[:consumer_key],
      :consumer_secret    => account[:consumer_secret],
      :oauth_token        => account[:oauth_token],
      :oauth_token_secret => account[:oauth_token_secret]
    )
    
    # search results
    if account[:search]
      account[:search].each { |search|
        tweets = @client.search( search[:item] )
        @article_type = 'twitter status'
        fetch_loop(tweets, account, search[:group])
      }
    end

    # mentions
    if account[:mentions]
      tweets = @client.mentions
      @article_type = 'twitter status'
      fetch_loop(tweets, account, account[:mentions][:group])
    end
    
    # direct messages
    if account[:direct_messages]
      tweets = @client.direct_messages
      @article_type = 'twitter direct-message'
      fetch_loop(tweets, account, account[:direct_messages][:group])
    end
    puts 'done'
  end

  def fetch_loop(tweets, account, group)

    # find tweets
    tweets.each do |tweet|
      
      # check if tweet is already imported
      puts '------------------------------------------------------'
      article = Ticket::Article.where( :message_id => tweet.id ).first

      # check if sender already exists
      next if article

      # use transaction
      ActiveRecord::Base.transaction do
        puts 'import tweet'
        fetch_import(tweet, account, group)
      end
      
      # execute ticket events      
      Ticket::Observer::Notification.transaction
    end
  end
  
  def fetch_import(tweet, account, group)
    
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
      sender = @client.user(tweet.from_user_id)
    end
    
    # check if parent exists
    user = nil, ticket = nil, article = nil
    if tweet['in_reply_to_status_id']
      puts 'import in_reply_tweet ' + tweet.in_reply_to_status_id.to_s
      tweet_sub = @client.status(tweet.in_reply_to_status_id)
#        puts tweet_sub.inspect
      (user, ticket, article) = fetch_import(tweet_sub, account, group)
    end
    
    # create stuff
    user = fetch_user_create(tweet, sender)
    if !ticket
      ticket = fetch_ticket_create(user, tweet, sender, account, group)
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
    if !user then
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
  
  def fetch_ticket_create(user, tweet, sender, account, group)

    puts '+++++++++++++++++++++++++++' + tweet.inspect
    # check if ticket exists
    if tweet['in_reply_to_status_id'] then
      puts 'tweet.in_reply_to_status_id found: ' + tweet.in_reply_to_status_id
      article = Ticket::Article.where( :message_id => tweet.in_reply_to_status_id ).first
      if article
        puts 'article with id found tweet.in_reply_to_status_id found: ' + tweet.in_reply_to_status_id
        return article.ticket
      end
    end
    
    # find if record already exists
    article = Ticket::Article.where( :message_id => tweet.id ).first
    if article
      return article.ticket
    end
    
#    auth = Authorization.where( :uid => tweet.sender.id, :provider => 'twitter' )
    puts 'custimer_id', user.id, user.inspect
    ticket = nil
    if @article_type == 'twitter direct-message'
      ticket = Ticket.where( :customer_id => user.id ).first
    end
    if !ticket then
      ticket = Ticket.create(
        :group_id           => Group.where( :name => group ).first.id,
        :customer_id        => user.id,
        :title              => tweet.text[0,40],
        :ticket_state_id    => Ticket::State.where( :name => 'new' ).first.id,
        :ticket_priority_id => Ticket::Priority.where( :name => '2 normal' ).first.id,
        :created_by_id      => user.id
      )
    end
    return ticket
  end
  
  def fetch_article_create(user,ticket,tweet, sender)

    # find if record already exists
    article = Ticket::Article.where( :message_id => tweet.id ).first
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
      :ticket_article_type_id   => Ticket::Article::Type.where(:name => @article_type).first.id,
      :ticket_article_sender_id => Ticket::Article::Sender.where(:name => 'Customer').first.id,
      :body                     => tweet.text,
      :from                     => sender.name,
      :to                       => to,
      :message_id               => tweet.id,
      :internal                 => false
    )

  end
  
  def send(atts, account)
#    logger.debug('tweeeeettttt!!!!!!')
    @client = Twitter::Client.new(
      :consumer_key       => account[:consumer_key],
      :consumer_secret    => account[:consumer_secret],
      :oauth_token        => account[:oauth_token],
      :oauth_token_secret => account[:oauth_token_secret]
    )
    puts 'to:' + atts[:to].to_s
    if atts[:type] == 'twitter direct-message' then
      dm = @client.direct_message_create(
        atts[:to].to_s,
        atts[:body].to_s,
        options = {}
      )
      puts dm.inspect
      return dm      
    end
      
    if atts[:type] == 'twitter status' then
      message = @client.update(
        atts[:body].to_s,
        options = {
          :in_reply_to_status_id => atts[:in_reply_to]
        }
      )
      puts message.inspect
      return message
    end

  end
end