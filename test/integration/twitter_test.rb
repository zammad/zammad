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

  {
    'TWITTER_CONSUMER_KEY'          => '1234',
    'TWITTER_CONSUMER_SECRET'       => '1234',
    'TWITTER_SYSTEM_LOGIN'          => '@system',
    'TWITTER_SYSTEM_ID'             => '1405469528',
    'TWITTER_SYSTEM_TOKEN'          => '1234',
    'TWITTER_SYSTEM_TOKEN_SECRET'   => '1234',
    'TWITTER_CUSTOMER_LOGIN'        => '@customer',
    'TWITTER_CUSTOMER_TOKEN'        => '1234',
    'TWITTER_CUSTOMER_TOKEN_SECRET' => '1234',
  }.each do |key, example_value|
    next if ENV[key]
    raise "ERROR: Need ENV #{key} - hint: export #{key}='#{example_value}'"
  end

  # app config
  consumer_key    = ENV['TWITTER_CONSUMER_KEY']
  consumer_secret = ENV['TWITTER_CONSUMER_SECRET']

  # armin_theo (is system and is following marion_bauer)
  system_login            = ENV['TWITTER_SYSTEM_LOGIN']
  system_id               = ENV['TWITTER_SYSTEM_ID']
  system_login_without_at = system_login[1, system_login.length]
  system_token            = ENV['TWITTER_SYSTEM_TOKEN']
  system_token_secret     = ENV['TWITTER_SYSTEM_TOKEN_SECRET']
  hash_tag1               = "#zarepl#{rand(999)}"
  hash_tag2               = "#citheo#{rand(999)}"

  # me_bauer (is customer and is following armin_theo)
  customer_login            = ENV['TWITTER_CUSTOMER_LOGIN']
  customer_login_without_at = customer_login[1, customer_login.length]
  customer_token            = ENV['TWITTER_CUSTOMER_TOKEN']
  customer_token_secret     = ENV['TWITTER_CUSTOMER_TOKEN_SECRET']

  # ensure channel configuration
  Channel.where(area: 'Twitter::Account').each(&:destroy)

  channel = Channel.create!(
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
        track_retweets: true,
        search: [
          {
            term: hash_tag2,
            group_id: group.id,
          },
          {
            term: hash_tag1,
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

    hash   = "#{hash_tag2}#{rand(999_999)}"
    user   = User.find(2)
    text   = "Today the weather is really #{rand_word}... #{hash}"
    ticket = Ticket.create!(
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
    article = Ticket::Article.create!(
      ticket_id:     ticket.id,
      body:          text,
      type:          Ticket::Article::Type.find_by(name: 'twitter status'),
      sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
      internal:      false,
      updated_by_id: 1,
      created_by_id: 1,
    )

    Scheduler.worker(true)

    article = Ticket::Article.find(article.id)
    assert(article, "outbound article created, text: #{text}")
    assert_equal(system_login, article.from, 'ticket article from')
    assert_equal('', article.to, 'ticket article to')

    ticket = Ticket.find(article.ticket_id)
    ticket.state = Ticket::State.find_by(name: 'closed')
    ticket.save!

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
    2.times {
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

    assert_equal('open', ticket.reload.state.name)

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

    hash  = "#{hash_tag1} ##{hash_gen}"
    text  = "Today #{rand_word}... #{hash}"
    tweet = client.update(
      text,
    )

    # fetch check system account
    sleep 20
    article = nil
    2.times {
      Channel.fetch

      # check if ticket and article has been created
      article = Ticket::Article.find_by(message_id: tweet.id)
      break if article
      sleep 20
    }
    assert(article, "Can't find tweet id #{tweet.id}/#{text}")
    assert_equal(customer_login, article.from, 'ticket article from')
    assert_nil(article.to, 'ticket article to')
    ticket = article.ticket
    assert_equal('new', ticket.reload.state.name)

    # send reply
    reply_text = "#{customer_login} on my side #weather#{hash_gen}"
    article = Ticket::Article.create!(
      ticket_id:     ticket.id,
      body:          reply_text,
      type:          Ticket::Article::Type.find_by(name: 'twitter status'),
      sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
      internal:      false,
      updated_by_id: 1,
      created_by_id: 1,
    )

    Scheduler.worker(true)
    assert_equal('open', ticket.reload.state.name)

    article = Ticket::Article.find(article.id)
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

    ticket = Ticket.find(article.ticket_id)
    ticket.state = Ticket::State.find_by(name: 'closed')
    ticket.save!

    # reply with zammad user directly
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = consumer_key
      config.consumer_secret     = consumer_secret
      config.access_token        = system_token
      config.access_token_secret = system_token_secret
    end

    hash  = "#{hash_tag1} ##{hash_gen}"
    text  = "Today #{system_login} #{rand_word}... #{hash}"
    tweet = client.update(
      text,
    )

    # fetch check system account
    sleep 20
    article = nil
    2.times {
      Channel.fetch

      # check if ticket and article has been created
      article = Ticket::Article.find_by(message_id: tweet.id)
      break if article
      sleep 20
    }

    assert(article, "Can't find tweet id #{tweet.id}/#{text}")
    assert_equal('closed', ticket.reload.state.name)
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
    dms.each { |dm|
      client.destroy_direct_message(dm.id)
    }
    client = Twitter::REST::Client.new(
      consumer_key:        consumer_key,
      consumer_secret:     consumer_secret,
      access_token:        customer_token,
      access_token_secret: customer_token_secret
    )
    dms = client.direct_messages(count: 100)
    dms.each { |dm|
      client.destroy_direct_message(dm.id)
    }
    hash  = "#citheo44 #{hash_gen}"
    text  = "How about #{rand_word} the details? #{hash} - #{'Long' * 50}"
    dm = client.create_direct_message(
      system_login_without_at,
      text,
    )
    assert(dm, "dm with ##{hash} created")

    # fetch check system account
    sleep 15
    article = nil
    1.times {
      Channel.fetch

      # check if ticket and article has been created
      article = Ticket::Article.find_by(message_id: dm.id)
      break if article
      sleep 10
    }

    assert(article, "inbound article '#{text}' created")
    assert_equal(customer_login, article.from, 'ticket article from')
    assert_equal(text, article.body, 'ticket article body')
    ticket = article.ticket
    assert(ticket, 'ticket of inbound article exists')
    assert(ticket.articles, 'ticket.articles exists')
    assert_equal(1, ticket.articles.count, 'ticket article inbound count')
    assert_equal(ticket.state.name, 'new')

    # reply via ticket
    outbound_article = Ticket::Article.create!(
      ticket_id:     ticket.id,
      to:            customer_login,
      body:          "Will call you later #{rand_word}!",
      type:          Ticket::Article::Type.find_by(name: 'twitter direct-message'),
      sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
      internal:      false,
      updated_by_id: 1,
      created_by_id: 1,
    )

    Scheduler.worker(true)

    outbound_article = Ticket::Article.find(outbound_article.id)
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
    1.times {
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
    1.times {
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

  test 'd track_retweets enabled' do

    # enable track_retweets
    channel[:options]['sync']['track_retweets'] = true
    channel.save!

    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = consumer_key
      config.consumer_secret     = consumer_secret
      config.access_token        = system_token
      config.access_token_secret = system_token_secret
    end

    hash  = "#{hash_tag1} ##{hash_gen}"
    text  = "Retweet me - I'm #{system_login} - #{rand_word}... #{hash}"
    tweet = client.update(text)

    client = Twitter::REST::Client.new(
      consumer_key:        consumer_key,
      consumer_secret:     consumer_secret,
      access_token:        customer_token,
      access_token_secret: customer_token_secret
    )

    retweet = client.retweet(tweet).first

    # fetch check system account
    sleep 15
    article = nil
    2.times {
      Channel.fetch

      # check if ticket and article has been created
      article = Ticket::Article.find_by(message_id: retweet.id)
      break if article
      sleep 10
    }

    assert(article, "retweet article '#{text}' created")
  end

  test 'e track_retweets disabled' do

    # disable track_retweets
    channel[:options]['sync']['track_retweets'] = false
    channel.save!

    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = consumer_key
      config.consumer_secret     = consumer_secret
      config.access_token        = system_token
      config.access_token_secret = system_token_secret
    end

    hash  = "#{hash_tag1} ##{hash_gen}"
    text  = "Retweet me - I'm #{system_login} - #{rand_word}... #{hash}"
    tweet = client.update(text)

    client = Twitter::REST::Client.new(
      consumer_key:        consumer_key,
      consumer_secret:     consumer_secret,
      access_token:        customer_token,
      access_token_secret: customer_token_secret
    )

    retweet = client.retweet(tweet).first

    # fetch check system account
    sleep 15
    article = nil
    2.times {
      Channel.fetch

      # check if ticket and article has been created
      article = Ticket::Article.find_by(message_id: retweet.id)
      break if article
      sleep 10
    }

    assert_nil(article, "retweet article '#{text}' not created")
  end

  test 'f streaming test' do
    thread = Thread.new {
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

    hash  = "#{hash_tag1} ##{hash_gen}"
    text  = "Today... #{rand_word} #{hash}"
    tweet = client.update(
      text,
    )

    article = nil
    5.times {
      Scheduler.worker(true)
      article = Ticket::Article.find_by(message_id: tweet.id)
      break if article
      ActiveRecord::Base.clear_all_connections!
      ActiveRecord::Base.connection.query_cache.clear
      sleep 10
    }
    assert(article, "article from customer with text '#{text}' message_id '#{tweet.id}' created")
    assert_equal(customer_login, article.from, 'ticket article from')
    assert_nil(article.to, 'ticket article to')

    # new tweet II - by me_bauer
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = consumer_key
      config.consumer_secret     = consumer_secret
      config.access_token        = customer_token
      config.access_token_secret = customer_token_secret
    end
    hash  = "#{hash_tag1} ##{rand(999_999)}"
    text  = "Today... #{rand_word}  #{hash}"
    tweet = client.update(
      text,
    )

    article = nil
    5.times {
      Scheduler.worker(true)
      article = Ticket::Article.find_by(message_id: tweet.id)
      break if article
      ActiveRecord::Base.clear_all_connections!
      ActiveRecord::Base.connection.query_cache.clear
      sleep 10
    }
    assert(article, "article from customer with text '#{text}' message_id '#{tweet.id}' created")
    assert_equal(customer_login, article.from, 'ticket article from')
    assert_nil(article.to, 'ticket article to')

    # send reply
    reply_text = "RE #{text}"
    article = Ticket::Article.create!(
      ticket_id:     article.ticket_id,
      body:          reply_text,
      type:          Ticket::Article::Type.find_by(name: 'twitter status'),
      sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
      internal:      false,
      updated_by_id: 1,
      created_by_id: 1,
    )

    Scheduler.worker(true)

    article = Ticket::Article.find(article.id)
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
    assert_equal(1, count, "tweet #{article.message_id}")

    channel_id = article.ticket.preferences[:channel_id]
    assert(channel_id)
    channel = Channel.find(channel_id)
    assert_equal('', channel.last_log_out)
    assert_equal('ok', channel.status_out)

    # get dm via stream
    client = Twitter::REST::Client.new(
      consumer_key:        consumer_key,
      consumer_secret:     consumer_secret,
      access_token:        customer_token,
      access_token_secret: customer_token_secret
    )
    hash = "#citheo44#{rand(999_999)}"
    text = "How about the #{rand_word}? #{hash}"
    dm   = client.create_direct_message(
      system_login_without_at,
      text,
    )
    assert(dm, "dm with ##{hash} created")

    article = nil
    5.times {
      Scheduler.worker(true)
      article = Ticket::Article.find_by(message_id: dm.id)
      break if article
      sleep 10
    }
    assert(article, "inbound article '#{text}' message_id '#{dm.id}' created")
    assert_equal(customer_login, article.from, 'ticket article from')
    assert_equal(system_login, article.to, 'ticket article to')
    thread.exit
    thread.join
  end

  test 'g streaming test retweet enabled' do
    thread = Thread.new {
      # enable track_retweets in current thread
      # since Threads are not spawned in the same scope
      # as the current test is running in .....
      channel_thread = Channel.find(channel.id)
      channel_thread[:options]['sync']['track_retweets'] = true
      channel_thread.save!

      Channel.stream
    }
    sleep 10

    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = consumer_key
      config.consumer_secret     = consumer_secret
      config.access_token        = system_token
      config.access_token_secret = system_token_secret
    end

    hash  = "#{hash_tag1} ##{hash_gen}"
    text  = "Retweet me - I'm #{system_login} - #{rand_word}... #{hash}"
    tweet = client.update(text)

    client = Twitter::REST::Client.new(
      consumer_key:        consumer_key,
      consumer_secret:     consumer_secret,
      access_token:        customer_token,
      access_token_secret: customer_token_secret
    )

    retweet = client.retweet(tweet).first

    # fetch check system account
    sleep 15
    article = nil
    2.times {
      Channel.fetch

      # check if ticket and article has been created
      article = Ticket::Article.find_by(message_id: retweet.id)
      break if article
      ActiveRecord::Base.clear_all_connections!
      ActiveRecord::Base.connection.query_cache.clear
      sleep 10
    }

    assert(article, "retweet article '#{text}' created")

    thread.exit
    thread.join
  end

  test 'h streaming test retweet disabled' do
    thread = Thread.new {
      # disable track_retweets in current thread
      # since Threads are not spawned in the same scope
      # as the current test is running in .....
      channel_thread = Channel.find(channel.id)
      channel_thread[:options]['sync']['track_retweets'] = false
      channel_thread.save!

      Channel.stream
    }
    sleep 10

    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = consumer_key
      config.consumer_secret     = consumer_secret
      config.access_token        = system_token
      config.access_token_secret = system_token_secret
    end

    hash  = "#{hash_tag1} ##{hash_gen}"
    text  = "Retweet me - I'm #{system_login} - #{rand_word}... #{hash}"
    tweet = client.update(text)

    client = Twitter::REST::Client.new(
      consumer_key:        consumer_key,
      consumer_secret:     consumer_secret,
      access_token:        customer_token,
      access_token_secret: customer_token_secret
    )

    retweet = client.retweet(tweet).first

    # fetch check system account
    article = nil
    4.times {
      # check if ticket and article has been created
      article = Ticket::Article.find_by(message_id: retweet.id)
      break if article
      sleep 10
    }

    assert_nil(article, "retweet article '#{text}' not created")

    thread.exit
    thread.join
  end

  test 'i restart stream after config of channel has changed' do
    hash = "#citheo#{rand(999)}"

    thread = Thread.new {
      Channel.stream
      sleep 10
      item = {
        term: hash,
        group_id: group.id,
      }
      channel_thread = Channel.find(channel.id)
      channel_thread[:options]['sync']['search'].push item
      channel_thread.save!
    }

    sleep 60

    # new tweet - by me_bauer
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = consumer_key
      config.consumer_secret     = consumer_secret
      config.access_token        = customer_token
      config.access_token_secret = customer_token_secret
    end

    hash  = "#{hash_tag1} ##{hash_gen}"
    text  = "Today... #{rand_word} #{hash}"
    tweet = client.update(
      text,
    )
    article = nil
    5.times {
      Scheduler.worker(true)
      article = Ticket::Article.find_by(message_id: tweet.id)
      break if article
      ActiveRecord::Base.clear_all_connections!
      ActiveRecord::Base.connection.query_cache.clear
      sleep 10
    }
    assert(article, "article from customer with text '#{text}' message_id '#{tweet.id}' created")
    assert_equal(customer_login, article.from, 'ticket article from')
    assert_nil(article.to, 'ticket article to')

    thread.exit
    thread.join

    channel_thread = Channel.find(channel.id)
    channel_thread[:options]['sync']['search'].pop
    channel_thread.save!
  end

  def hash_gen
    rand(999).to_s + (0...10).map { ('a'..'z').to_a[rand(26)] }.join
  end

  def rand_word
    [
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
    ].sample
  end

end
