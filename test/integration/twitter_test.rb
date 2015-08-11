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
  consumer_key    = 'd2zoZBmMXmT7KLPgEHSzpw'
  consumer_secret = 'QMUrlyDlqjITCkWdrOgsTxMVVLxr4A4IW3DIgtIg'

  # armin_theo (is system and is following marion_bauer)
  armin_theo_token        = '1405469528-WQ6XHizgrbYasUwjp0I0TUONhftNkrfrpgFLrdc'
  armin_theo_token_secret = '0LHChGFlQx9jSxM8tkBsuDOMhbJMSXTL2zKJJO5Xk'

  # me_bauer (is following armin_theo)
  me_bauer_token        = '1406098795-XQTjg1Zj5uVW0C11NNpNA4xopyclRJJoriWis0I'
  me_bauer_token_secret = 'T8ph5afeSDjGDA9X1ZBlzEvoSiXfN266ZZUMj5UaY'

  # add channel
  current = Channel.where( adapter: 'Twitter' )
  current.each(&:destroy)
  Channel.create(
    adapter: 'Twitter',
    area: 'Twitter::Inbound',
    options: {
      auth: {
        consumer_key:       consumer_key,
        consumer_secret:    consumer_secret,
        oauth_token:        armin_theo_token,
        oauth_token_secret: armin_theo_token_secret,
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

  test 'new outbound and reply' do

    hash   = '#citheo42' + rand(9999).to_s
    user   = User.find(2)
    text   = "Today the weather is really nice... #{hash}"
    ticket = Ticket.create(
      title:         text[0, 40],
      customer_id:   user.id,
      group_id:      2,
      state:         Ticket::State.find_by( name: 'new' ),
      priority:      Ticket::Priority.find_by( name: '2 normal' ),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert( ticket, "outbound ticket created, text: #{text}" )

    article = Ticket::Article.create(
      ticket_id:     ticket.id,
      body:          text,
      type:          Ticket::Article::Type.find_by( name: 'twitter status' ),
      sender:        Ticket::Article::Sender.find_by( name: 'Agent' ),
      internal:      false,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert( article, "outbound article created, text: #{text}" )

    # reply by me_bauer
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = consumer_key
      config.consumer_secret     = consumer_secret
      config.access_token        = me_bauer_token
      config.access_token_secret = me_bauer_token_secret
    end

    tweet_found = false
    client.user_timeline('armin_theo').each { |tweet|

      next if tweet.id != article.message_id
      tweet_found = true
      break
    }
    assert( tweet_found, "found outbound '#{text}' tweet '#{article.message_id}'" )

    reply_text = '@armin_theo on my side the weather is nice, too! 😍😍😍 #weather' + rand(9999).to_s
    tweet = client.update(
      reply_text,
      {
        in_reply_to_status_id: article.message_id
      }
    )

    # fetch check system account
    Channel.fetch

    # check if follow up article has been created
    article = Ticket::Article.find_by( message_id: tweet.id )

    assert( article, "article tweet '#{tweet.id}' imported" )
    assert_equal( 2, article.ticket.articles.count, 'ticket article inbound count' )
    assert_equal( reply_text.utf8_to_3bytesutf8, ticket.articles.last.body, 'ticket article inbound body' )
  end

  test 'new inbound and reply' do

    # new tweet by me_bauer
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = consumer_key
      config.consumer_secret     = consumer_secret
      config.access_token        = me_bauer_token
      config.access_token_secret = me_bauer_token_secret
    end

    hash  = '#citheo24 #' + rand(9999).to_s
    text  = "Today... #{hash}"
    tweet = client.update(
      text,
    )
    sleep 20

    # fetch check system account
    Channel.fetch

    # fetch check system account
    article = nil
    (1..4).each {
      Channel.fetch

      # check if ticket and article has been created
      article = Ticket::Article.find_by( message_id: tweet.id )

      break if article

      sleep 5
    }
    assert(article)
    ticket = article.ticket

    # send reply
    reply_text = '@armin_theo on my side #weather' + rand(9999).to_s
    article = Ticket::Article.create(
      ticket_id:     ticket.id,
      body:          reply_text,
      type:          Ticket::Article::Type.find_by( name: 'twitter status' ),
      sender:        Ticket::Article::Sender.find_by( name: 'Agent' ),
      internal:      false,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert( article, "outbound article created, text: #{reply_text}" )

    tweet_found = false
    client.user_timeline('armin_theo').each { |local_tweet|

      next if local_tweet.id != article.message_id
      tweet_found = true
      break
    }
    assert( tweet_found, "found outbound '#{reply_text}' tweet '#{article.message_id}'" )
  end

  test 'new by direct message inbound' do

    # cleanup direct messages of system
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = consumer_key
      config.consumer_secret     = consumer_secret
      config.access_token        = armin_theo_token
      config.access_token_secret = armin_theo_token_secret
    end
    dms = client.direct_messages( count: 200 )
    dms.each {|dm|
      client.destroy_direct_message(dm.id)
    }
    client = Twitter::REST::Client.new(
      consumer_key:        consumer_key,
      consumer_secret:     consumer_secret,
      access_token:        me_bauer_token,
      access_token_secret: me_bauer_token_secret
    )
    dms = client.direct_messages( count: 200 )
    dms.each {|dm|
      client.destroy_direct_message(dm.id)
    }

    hash  = '#citheo44' + rand(9999).to_s
    text  = 'How about the details? ' + hash
    dm = client.create_direct_message(
      'armin_theo',
      text,
    )
    assert( dm, "dm with ##{hash} created" )

    # fetch check system account
    article = nil
    (1..4).each {
      Channel.fetch

      # check if ticket and article has been created
      article = Ticket::Article.find_by( message_id: dm.id )

      break if article

      sleep 5
    }

    assert( article, "inbound article '#{text}' created" )
    ticket = article.ticket
    assert( ticket, 'ticket of inbound article exists' )
    assert( ticket.articles, 'ticket.articles exists' )
    assert_equal( 1, ticket.articles.count, 'ticket article inbound count' )
    assert_equal( ticket.state.name, 'new' )

    # reply via ticket
    outbound_article = Ticket::Article.create(
      ticket_id:     ticket.id,
      to:            'me_bauer',
      body:          'Will call you later!',
      type:          Ticket::Article::Type.find_by( name: 'twitter direct-message' ),
      sender:        Ticket::Article::Sender.find_by( name: 'Agent' ),
      internal:      false,
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket.state = Ticket::State.find_by( name: 'pending reminder' )
    ticket.save

    assert( outbound_article, 'outbound article created' )
    assert_equal( 2, outbound_article.ticket.articles.count, 'ticket article outbound count' )

    text  = 'Ok. ' + hash
    dm = client.create_direct_message(
      'armin_theo',
      text,
    )
    assert( dm, "second dm with ##{hash} created" )

    # fetch check system account
    article = nil
    (1..4).each {
      Channel.fetch

      # check if ticket and article has been created
      article = Ticket::Article.find_by( message_id: dm.id )

      break if article

      sleep 5
    }

    assert( article, "inbound article '#{text}' created" )
    ticket = article.ticket
    assert( ticket, 'ticket of inbound article exists' )
    assert( ticket.articles, 'ticket.articles exists' )
    assert_equal( 3, ticket.articles.count, 'ticket article inbound count' )
    assert_equal( ticket.state.name, 'open' )

    # close dm ticket, next dm should open a new
    ticket.state = Ticket::State.find_by( name: 'closed' )
    ticket.save

    text = 'Thanks for your call . I just have one question. ' + hash
    dm   = client.create_direct_message(
      'armin_theo',
      text,
    )
    assert( dm, "third dm with ##{hash} created" )

    # fetch check system account
    article = nil
    (1..4).each {
      Channel.fetch

      # check if ticket and article has been created
      article = Ticket::Article.find_by( message_id: dm.id )

      break if article

      sleep 5
    }

    assert( article, "inbound article '#{text}' created" )
    ticket = article.ticket
    assert( ticket, 'ticket of inbound article exists' )
    assert( ticket.articles, 'ticket.articles exists' )
    assert_equal( 1, ticket.articles.count, 'ticket article inbound count' )
    assert_equal( ticket.state.name, 'new' )
  end
end
