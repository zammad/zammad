# encoding: utf-8
require 'integration_test_helper'

class TwitterTest < ActiveSupport::TestCase

  # set system mode to done / to activate
  Setting.set('system_init_done', true)

  # needed to check correct behavior
  Group.create_if_not_exists(
    id: 2,
    name: 'Twitter',
    note: 'All Tweets.',
    updated_by_id: 1,
    created_by_id: 1
  )

  # app config
  if !ENV['TWITTER_CONSUMER_KEY']
    fail "ERROR: Need TWITTER_CONSUMER_KEY - hint TWITTER_CONSUMER_KEY='1234'"
  end
  if !ENV['TWITTER_CONSUMER_SECRET']
    fail "ERROR: Need TWITTER_CONSUMER_SECRET - hint TWITTER_CONSUMER_SECRET='1234'"
  end
  consumer_key    = ENV['TWITTER_CONSUMER_KEY']
  consumer_secret = ENV['TWITTER_CONSUMER_SECRET']

  # armin_theo (is system and is following marion_bauer)
  if !ENV['TWITTER_SYSTEM_TOKEN']
    fail "ERROR: Need TWITTER_SYSTEM_TOKEN - hint TWITTER_SYSTEM_TOKEN='1234'"
  end
  if !ENV['TWITTER_SYSTEM_TOKEN_SECRET']
    fail "ERROR: Need TWITTER_SYSTEM_TOKEN_SECRET - hint TWITTER_SYSTEM_TOKEN_SECRET='1234'"
  end
  armin_theo_token        = ENV['TWITTER_SYSTEM_TOKEN']
  armin_theo_token_secret = ENV['TWITTER_SYSTEM_TOKEN_SECRET']

  # me_bauer (is customer and is following armin_theo)
  if !ENV['TWITTER_CUSTOMER_TOKEN']
    fail "ERROR: Need CUSTOMER_TOKEN - hint TWITTER_CUSTOMER_TOKEN='1234'"
  end
  if !ENV['TWITTER_CUSTOMER_TOKEN_SECRET']
    fail "ERROR: Need CUSTOMER_TOKEN_SECRET - hint TWITTER_CUSTOMER_TOKEN_SECRET='1234'"
  end
  me_bauer_token        = ENV['TWITTER_CUSTOMER_TOKEN']
  me_bauer_token_secret = ENV['TWITTER_CUSTOMER_TOKEN_SECRET']

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
        oauth_token:        armin_theo_token,
        oauth_token_secret: armin_theo_token_secret,
      },
      user: {
        screen_name: '@armin_theo',
        id: '1234',
      },
      sync: {
        search: [
          {
            term: '#citheo42',
            group_id: 2,
          },
          {
            term: '#citheo24',
            group_id: 1,
          },
        ],
        mentions: {
          group_id: 2,
        },
        direct_messages: {
          group_id: 2,
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
    text   = "Today the weather is really nice... #{hash}"
    ticket = Ticket.create(
      title:         text[0, 40],
      customer_id:   user.id,
      group_id:      2,
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
    assert_equal('@armin_theo', article.from, 'ticket article from')
    assert_equal('', article.to, 'ticket article to')

    # reply by me_bauer
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = consumer_key
      config.consumer_secret     = consumer_secret
      config.access_token        = me_bauer_token
      config.access_token_secret = me_bauer_token_secret
    end

    tweet_found = false
    client.user_timeline('armin_theo').each { |tweet|

      next if tweet.id.to_s != article.message_id.to_s
      tweet_found = true
      break
    }
    assert(tweet_found, "found outbound '#{text}' tweet '#{article.message_id}'")

    reply_text = '@armin_theo on my side the weather is nice, too! 😍😍😍 #weather' + rand(999_999).to_s
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
    assert_equal('@me_bauer', article.from, 'ticket article from')
    assert_equal('@armin_theo', article.to, 'ticket article to')
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
      config.access_token        = me_bauer_token
      config.access_token_secret = me_bauer_token_secret
    end

    hash  = '#citheo24 #' + rand(999_999).to_s
    text  = "Today... #{hash}"
    tweet = client.update(
      text,
    )

    # fetch check system account
    sleep 15
    article = nil
    (1..3).each {
      Channel.fetch

      # check if ticket and article has been created
      article = Ticket::Article.find_by(message_id: tweet.id)
      break if article
      sleep 15
    }
    assert(article)
    assert_equal('@me_bauer', article.from, 'ticket article from')
    assert_equal(nil, article.to, 'ticket article to')
    ticket = article.ticket

    # send reply
    reply_text = '@me_bauer on my side #weather' + rand(999_999).to_s
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
    assert_equal('@armin_theo', article.from, 'ticket article from')
    assert_equal('@me_bauer', article.to, 'ticket article to')
    sleep 5
    tweet_found = false
    client.user_timeline('armin_theo').each { |local_tweet|
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
      config.access_token        = armin_theo_token
      config.access_token_secret = armin_theo_token_secret
    end
    dms = client.direct_messages(count: 100)
    dms.each {|dm|
      client.destroy_direct_message(dm.id)
    }
    client = Twitter::REST::Client.new(
      consumer_key:        consumer_key,
      consumer_secret:     consumer_secret,
      access_token:        me_bauer_token,
      access_token_secret: me_bauer_token_secret
    )
    dms = client.direct_messages(count: 100)
    dms.each {|dm|
      client.destroy_direct_message(dm.id)
    }
    hash  = '#citheo44' + rand(999_999).to_s
    text  = 'How about the details? ' + hash
    dm = client.create_direct_message(
      'armin_theo',
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
    assert_equal('@me_bauer', article.from, 'ticket article from')
    assert_equal('@armin_theo', article.to, 'ticket article to')
    ticket = article.ticket
    assert(ticket, 'ticket of inbound article exists')
    assert(ticket.articles, 'ticket.articles exists')
    assert_equal(1, ticket.articles.count, 'ticket article inbound count')
    assert_equal(ticket.state.name, 'new')

    # reply via ticket
    outbound_article = Ticket::Article.create(
      ticket_id:     ticket.id,
      to:            'me_bauer',
      body:          'Will call you later!',
      type:          Ticket::Article::Type.find_by(name: 'twitter direct-message'),
      sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
      internal:      false,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(outbound_article, 'outbound article created')
    assert_equal(2, outbound_article.ticket.articles.count, 'ticket article outbound count')
    assert_equal('@armin_theo', outbound_article.from, 'ticket article from')
    assert_equal('@me_bauer', outbound_article.to, 'ticket article to')
    ticket.state = Ticket::State.find_by(name: 'pending reminder')
    ticket.save

    text = 'Ok. ' + hash
    dm = client.create_direct_message(
      'armin_theo',
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
    assert_equal('@me_bauer', article.from, 'ticket article inbound from')
    assert_equal('@armin_theo', article.to, 'ticket article inbound to')
    assert_equal(article.ticket.id, ticket.id, 'still the same ticket')
    ticket = article.ticket
    assert(ticket, 'ticket of inbound article exists')
    assert(ticket.articles, 'ticket.articles exists')
    assert_equal(3, ticket.articles.count, 'ticket article inbound count')
    assert_equal(ticket.state.name, 'open')

    # close dm ticket, next dm should open a new
    ticket.state = Ticket::State.find_by(name: 'closed')
    ticket.save

    text = 'Thanks for your call . I just have one question. ' + hash
    dm   = client.create_direct_message(
      'armin_theo',
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

    assert(article, "inbound article '#{text}' created")
    assert_equal('@me_bauer', article.from, 'ticket article inbound from')
    assert_equal('@armin_theo', article.to, 'ticket article inbound to')
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
      config.access_token        = me_bauer_token
      config.access_token_secret = me_bauer_token_secret
    end
    hash  = '#citheo24 #' + rand(999_999).to_s
    text  = "Today... #{hash}"
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
    assert_equal('@me_bauer', article.from, 'ticket article from')
    assert_equal(nil, article.to, 'ticket article to')

    # new tweet II - by me_bauer
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = consumer_key
      config.consumer_secret     = consumer_secret
      config.access_token        = me_bauer_token
      config.access_token_secret = me_bauer_token_secret
    end
    hash  = '#citheo24 #' + rand(999_999).to_s
    text  = "Today...2  #{hash}"
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
    assert_equal('@me_bauer', article.from, 'ticket article from')
    assert_equal(nil, article.to, 'ticket article to')

    # get dm via stream
    client = Twitter::REST::Client.new(
      consumer_key:        consumer_key,
      consumer_secret:     consumer_secret,
      access_token:        me_bauer_token,
      access_token_secret: me_bauer_token_secret
    )
    hash  = '#citheo44' + rand(999_999).to_s
    text  = 'How about the details? ' + hash
    dm = client.create_direct_message(
      'armin_theo',
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
    assert_equal('@me_bauer', article.from, 'ticket article from')
    assert_equal('@armin_theo', article.to, 'ticket article to')

  end

end
