# encoding: utf-8
require 'integration_test_helper'

class TwitterTest < ActiveSupport::TestCase

  # set system mode to done / to activate
  Setting.set('system_init_done', true)

  # needed to check correct behavior
  group = Group.create_if_not_exists(
    name: 'Twitter',
    note: 'All Tweets.',
    updated_by_id: 1,
    created_by_id: 1
  )

  # app config
  if !ENV['TWITTER_CONSUMER_KEY']
    raise "ERROR: Need TWITTER_CONSUMER_KEY - hint TWITTER_CONSUMER_KEY='1234'"
  end
  if !ENV['TWITTER_CONSUMER_SECRET']
    raise "ERROR: Need TWITTER_CONSUMER_SECRET - hint TWITTER_CONSUMER_SECRET='1234'"
  end
  consumer_key    = ENV['TWITTER_CONSUMER_KEY']
  consumer_secret = ENV['TWITTER_CONSUMER_SECRET']

  # armin_theo (is system and is following marion_bauer)
  if !ENV['TWITTER_SYSTEM_LOGIN']
    raise "ERROR: Need TWITTER_SYSTEM_LOGIN - hint TWITTER_SYSTEM_LOGIN='@system'"
  end
  if !ENV['TWITTER_SYSTEM_ID']
    raise "ERROR: Need TWITTER_SYSTEM_ID - hint TWITTER_SYSTEM_ID='1405469528'"
  end
  if !ENV['TWITTER_SYSTEM_TOKEN']
    raise "ERROR: Need TWITTER_SYSTEM_TOKEN - hint TWITTER_SYSTEM_TOKEN='1234'"
  end
  if !ENV['TWITTER_SYSTEM_TOKEN_SECRET']
    raise "ERROR: Need TWITTER_SYSTEM_TOKEN_SECRET - hint TWITTER_SYSTEM_TOKEN_SECRET='1234'"
  end
  system_login            = ENV['TWITTER_SYSTEM_LOGIN']
  system_id               = ENV['TWITTER_SYSTEM_ID']
  system_login_without_at = system_login[1, system_login.length]
  system_token            = ENV['TWITTER_SYSTEM_TOKEN']
  system_token_secret     = ENV['TWITTER_SYSTEM_TOKEN_SECRET']

  # me_bauer (is customer and is following armin_theo)
  if !ENV['TWITTER_CUSTOMER_LOGIN']
    raise "ERROR: Need CUSTOMER_LOGIN - hint TWITTER_CUSTOMER_LOGIN='@customer'"
  end
  if !ENV['TWITTER_CUSTOMER_TOKEN']
    raise "ERROR: Need CUSTOMER_TOKEN - hint TWITTER_CUSTOMER_TOKEN='1234'"
  end
  if !ENV['TWITTER_CUSTOMER_TOKEN_SECRET']
    raise "ERROR: Need CUSTOMER_TOKEN_SECRET - hint TWITTER_CUSTOMER_TOKEN_SECRET='1234'"
  end
  customer_login        = ENV['TWITTER_CUSTOMER_LOGIN']
  customer_token        = ENV['TWITTER_CUSTOMER_TOKEN']
  customer_token_secret = ENV['TWITTER_CUSTOMER_TOKEN_SECRET']

  # add channel
  current = Channel.where(area: 'Twitter::Account')
  current.each(&:destroy)
  channel = Channel.create(
    area: 'Twitter::Account',
    options: {
      adapter: 'twitter',
      auth: {
        consumer_key:       consumer_key,
        consumer_secret:    consumer_secret,
        oauth_token:        system_token,
        oauth_token_secret: system_token_secret,
      },
      user: {
        screen_name: system_login,
        id: system_id,
      },
      sync: {
        search: [
          {
            term: '#citheo42',
            group_id: group.id,
          },
          {
            term: '#zarepl24',
            group_id: 1,
          },
        ],
        mentions: {
          group_id: group.id,
        },
        direct_messages: {
          group_id: group.id,
        }
      }
    },
    active: true,
    created_by_id: 1,
    updated_by_id: 1,
  )

  test 'a new outbound and reply' do

    hash   = '#citheo42' + rand(999_999).to_s
    user   = User.find(2)
    text   = "Today the weather is really #{rand_word}... #{hash}"
    ticket = Ticket.create(
      title:         text[0, 40],
      customer_id:   user.id,
      group_id:      group.id,
      state:         Ticket::State.find_by(name: 'new'),
      priority:      Ticket::Priority.find_by(name: '2 normal'),
      preferences: {
        channel_id: channel.id,
      },
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket, "outbound ticket created, text: #{text}")
    article = Ticket::Article.create(
      ticket_id:     ticket.id,
      body:          text,
      type:          Ticket::Article::Type.find_by(name: 'twitter status'),
      sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
      internal:      false,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(article, "outbound article created, text: #{text}")
    assert_equal(system_login, article.from, 'ticket article from')
    assert_equal('', article.to, 'ticket article to')

    # reply by me_bauer
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = consumer_key
      config.consumer_secret     = consumer_secret
      config.access_token        = customer_token
      config.access_token_secret = customer_token_secret
    end

    tweet_found = false
    client.user_timeline(system_login_without_at).each { |tweet|

      next if tweet.id.to_s != article.message_id.to_s
      tweet_found = true
      break
    }
    assert(tweet_found, "found outbound '#{text}' tweet '#{article.message_id}'")

    reply_text = "#{system_login} on my side the weather is nice, too! 😍😍😍 #weather#{rand(999_999)}"
    tweet = client.update(
      reply_text,
      {
        in_reply_to_status_id: article.message_id
      }
    )

    # fetch check system account
    sleep 10
    article = nil
    (1..2).each {
      Channel.fetch

      # check if follow up article has been created
      article = Ticket::Article.find_by(message_id: tweet.id)
      break if article
      sleep 10
    }

    assert(article, "article tweet '#{tweet.id}' imported")
    assert_equal(customer_login, article.from, 'ticket article from')
    assert_equal(system_login, article.to, 'ticket article to')
    assert_equal(tweet.id.to_s, article.message_id, 'ticket article inbound message_id')
    assert_equal(2, article.ticket.articles.count, 'ticket article inbound count')
    assert_equal(reply_text.utf8_to_3bytesutf8, ticket.articles.last.body, 'ticket article inbound body')

    channel = Channel.find(channel.id)
    assert_equal('', channel.last_log_out)
    assert_equal('ok', channel.status_out)
    assert_equal('', channel.last_log_in)
    assert_equal('ok', channel.status_in)
  end

  test 'b new inbound and reply' do

    # new tweet by me_bauer
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = consumer_key
      config.consumer_secret     = consumer_secret
      config.access_token        = customer_token
      config.access_token_secret = customer_token_secret
    end

    hash  = "#zarepl24 ##{hash_gen}"
    text  = "Today #{rand_word}... #{hash}"
    tweet = client.update(
      text,
    )

    # fetch check system account
    sleep 20
    article = nil
    (1..3).each {
      Channel.fetch

      # check if ticket and article has been created
      article = Ticket::Article.find_by(message_id: tweet.id)
      break if article
      sleep 20
    }
    assert(article, "Can't find tweet id #{tweet.id}/#{text}")
    assert_equal(customer_login, article.from, 'ticket article from')
    assert_equal(nil, article.to, 'ticket article to')
    ticket = article.ticket

    # send reply
    reply_text = "#{customer_login} on my side #weather#{hash_gen}"
    article = Ticket::Article.create(
      ticket_id:     ticket.id,
      body:          reply_text,
      type:          Ticket::Article::Type.find_by(name: 'twitter status'),
      sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
      internal:      false,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(article, "outbound article created, text: #{reply_text}")
    assert_equal(system_login, article.from, 'ticket article from')
    assert_equal(customer_login, article.to, 'ticket article to')
    sleep 5
    tweet_found = false
    client.user_timeline(system_login_without_at).each { |local_tweet|
      sleep 10
      next if local_tweet.id.to_s != article.message_id.to_s
      tweet_found = true
      break
    }
    assert(tweet_found, "found outbound '#{reply_text}' tweet '#{article.message_id}'")

    channel = Channel.find(channel.id)
    assert_equal('', channel.last_log_out)
    assert_equal('ok', channel.status_out)
    assert_equal('', channel.last_log_in)
    assert_equal('ok', channel.status_in)
  end

  test 'c new by direct message inbound' do

    # cleanup direct messages of system
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = consumer_key
      config.consumer_secret     = consumer_secret
      config.access_token        = system_token
      config.access_token_secret = system_token_secret
    end
    dms = client.direct_messages(count: 100)
    dms.each {|dm|
      client.destroy_direct_message(dm.id)
    }
    client = Twitter::REST::Client.new(
      consumer_key:        consumer_key,
      consumer_secret:     consumer_secret,
      access_token:        customer_token,
      access_token_secret: customer_token_secret
    )
    dms = client.direct_messages(count: 100)
    dms.each {|dm|
      client.destroy_direct_message(dm.id)
    }
    hash  = "#citheo44 #{hash_gen}"
    text  = "How about #{rand_word} the details? #{hash}"
    dm = client.create_direct_message(
      system_login_without_at,
      text,
    )
    assert(dm, "dm with ##{hash} created")

    # fetch check system account
    sleep 15
    article = nil
    (1..2).each {
      Channel.fetch

      # check if ticket and article has been created
      article = Ticket::Article.find_by(message_id: dm.id)
      break if article
      sleep 10
    }

    assert(article, "inbound article '#{text}' created")
    assert_equal(customer_login, article.from, 'ticket article from')
    assert_equal(system_login, article.to, 'ticket article to')
    ticket = article.ticket
    assert(ticket, 'ticket of inbound article exists')
    assert(ticket.articles, 'ticket.articles exists')
    assert_equal(1, ticket.articles.count, 'ticket article inbound count')
    assert_equal(ticket.state.name, 'new')

    # reply via ticket
    outbound_article = Ticket::Article.create(
      ticket_id:     ticket.id,
      to:            customer_login,
      body:          "Will call you later #{rand_word}!",
      type:          Ticket::Article::Type.find_by(name: 'twitter direct-message'),
      sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
      internal:      false,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(outbound_article, 'outbound article created')
    assert_equal(2, outbound_article.ticket.articles.count, 'ticket article outbound count')
    assert_equal(system_login, outbound_article.from, 'ticket article from')
    assert_equal(customer_login, outbound_article.to, 'ticket article to')
    ticket.state = Ticket::State.find_by(name: 'pending reminder')
    ticket.save

    text = "#{rand_word}. #{hash}"
    dm = client.create_direct_message(
      system_login_without_at,
      text,
    )
    assert(dm, "second dm with ##{hash} created")

    # fetch check system account
    sleep 15
    article = nil
    (1..2).each {
      Channel.fetch

      # check if ticket and article has been created
      article = Ticket::Article.find_by(message_id: dm.id)
      break if article
      sleep 10
    }

    assert(article, "inbound article '#{text}' created")
    assert_equal(customer_login, article.from, 'ticket article inbound from')
    assert_equal(system_login, article.to, 'ticket article inbound to')
    assert_equal(article.ticket.id, ticket.id, 'still the same ticket')
    ticket = article.ticket
    assert(ticket, 'ticket of inbound article exists')
    assert(ticket.articles, 'ticket.articles exists')
    assert_equal(3, ticket.articles.count, 'ticket article inbound count')
    assert_equal(ticket.state.name, 'open')

    # close dm ticket, next dm should open a new
    ticket.state = Ticket::State.find_by(name: 'closed')
    ticket.save

    text = "Thanks #{rand_word} for your call. I just have one question. #{hash}"
    dm   = client.create_direct_message(
      system_login_without_at,
      text,
    )
    assert(dm, "third dm with ##{hash} created")

    # fetch check system account
    sleep 15
    article = nil
    (1..2).each {
      Channel.fetch

      # check if ticket and article has been created
      article = Ticket::Article.find_by(message_id: dm.id)
      break if article
      sleep 15
    }

    assert(article, "inbound article '#{text}' created with dm id #{dm.id}")
    assert_equal(customer_login, article.from, 'ticket article inbound from')
    assert_equal(system_login, article.to, 'ticket article inbound to')
    ticket = article.ticket
    assert(ticket, 'ticket of inbound article exists')
    assert(ticket.articles, 'ticket.articles exists')
    assert_equal(1, ticket.articles.count, 'ticket article inbound count')
    assert_equal(ticket.state.name, 'new')

    channel = Channel.find(channel.id)
    assert_equal('', channel.last_log_out)
    assert_equal('ok', channel.status_out)
    assert_equal('', channel.last_log_in)
    assert_equal('ok', channel.status_in)
  end

  test 'd streaming test' do
    Thread.new {
      Channel.stream
    }
    sleep 10

    # new tweet I - by me_bauer
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = consumer_key
      config.consumer_secret     = consumer_secret
      config.access_token        = customer_token
      config.access_token_secret = customer_token_secret
    end
    hash  = '#zarepl24 #' + hash_gen
    text  = "Today... #{rand_word} #{hash}"
    tweet = client.update(
      text,
    )
    sleep 10
    article = nil
    (1..2).each {
      article = Ticket::Article.find_by(message_id: tweet.id)
      break if article
      sleep 15
    }
    assert(article)
    assert_equal(customer_login, article.from, 'ticket article from')
    assert_equal(nil, article.to, 'ticket article to')

    # new tweet II - by me_bauer
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = consumer_key
      config.consumer_secret     = consumer_secret
      config.access_token        = customer_token
      config.access_token_secret = customer_token_secret
    end
    hash  = '#zarepl24 #' + rand(999_999).to_s
    text  = "Today... #{rand_word}  #{hash}"
    tweet = client.update(
      text,
    )
    ActiveRecord::Base.connection.reconnect!
    sleep 10
    article = nil
    (1..2).each {
      article = Ticket::Article.find_by(message_id: tweet.id)
      break if article
      sleep 15
    }
    assert(article)
    assert_equal(customer_login, article.from, 'ticket article from')
    assert_equal(nil, article.to, 'ticket article to')

    # send reply
    reply_text = "RE #{text}"
    article = Ticket::Article.create(
      ticket_id:     article.ticket_id,
      body:          reply_text,
      type:          Ticket::Article::Type.find_by(name: 'twitter status'),
      sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
      internal:      false,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(article, "outbound article created, text: #{reply_text}")
    assert_equal(system_login, article.from, 'ticket article from')
    assert_equal('', article.to, 'ticket article to')
    sleep 5

    tweet_found = false
    client.user_timeline(system_login_without_at).each { |local_tweet|
      sleep 10
      next if local_tweet.id.to_s != article.message_id.to_s
      tweet_found = true
      break
    }
    assert(tweet_found, "found outbound '#{reply_text}' tweet '#{article.message_id}'")

    count = Ticket::Article.where(message_id: article.message_id).count
    assert_equal(1, count)

    channel_id = article.ticket.preferences[:channel_id]
    assert(channel_id)
    channel = Channel.find(channel_id)
    assert_equal('', channel.last_log_out)
    assert_equal('ok', channel.status_out)
    #assert_equal('', channel.last_log_in)
    #assert_equal('ok', channel.status_in)

    # get dm via stream
    client = Twitter::REST::Client.new(
      consumer_key:        consumer_key,
      consumer_secret:     consumer_secret,
      access_token:        customer_token,
      access_token_secret: customer_token_secret
    )
    hash  = '#citheo44' + rand(999_999).to_s
    text  = "How about the #{rand_word}? " + hash
    dm = client.create_direct_message(
      system_login_without_at,
      text,
    )
    assert(dm, "dm with ##{hash} created")
    #ActiveRecord::Base.connection.reconnect!
    sleep 10
    article = nil
    (1..2).each {
      article = Ticket::Article.find_by(message_id: dm.id)
      break if article
      sleep 10
    }
    assert(article, "inbound article '#{text}' created")
    assert_equal(customer_login, article.from, 'ticket article from')
    assert_equal(system_login, article.to, 'ticket article to')

  end

  def hash_gen
    rand(999).to_s + (0...10).map { ('a'..'z').to_a[rand(26)] }.join
  end

  def rand_word
    words = [
      'dog',
      'cat',
      'house',
      'home',
      'yesterday',
      'tomorrow',
      'new york',
      'berlin',
      'coffee script',
      'java script',
      'bob smith',
      'be open',
      'really nice',
      'stay tuned',
      'be a good boy',
      'invent new things',
    ]
    words[rand(words.length)]
  end

end
