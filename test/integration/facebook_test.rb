# encoding: utf-8
require 'integration_test_helper'

class FacebookTest < ActiveSupport::TestCase

  # set system mode to done / to activate
  Setting.set('system_init_done', true)

  # needed to check correct behavior
  Group.create_if_not_exists(
    id: 2,
    name: 'Facebook',
    note: 'All Facebook feed posts.',
    updated_by_id: 1,
    created_by_id: 1
  )

  provider_key = 'CAACEdEose0cBAC56WJvrGb5avKbTlH0c7P4xZCZBfT8zG4nkgEWeFKGnnpNZC8xeedXzmqZCxEUrAumX245T4MborvAmRW52PSpuDiXwXXSMjYaZCJOih5v6CsP3xrZAfGxhPWBbI8dSoquBv8eRbUAMSir9SDSoDeKJSdSfhuytqx5wfveE8YibzT2ZAwYz0d7d2QZAN4b10d9j9UpBhXCCCahj4hyk9JQZD'
  consumer_key = 'CAACEdEose0cBAHZCXAQ68snZBf2C7jT6G7pVXaWajbZCZAZAFWRZAVUb9FAMXHZBQECZBX0iL5qOeTsZA0mnR0586XTq9vYiWP8Y3qCzftrd9hnsP7J9VB6APnR67NEdY8SozxIFtctQA9Xp4Lb8lbxBmig2v5oXRIH513kImPYXJoCFUlQs0aJeZBCtRG6BekfPs5GPZB8tieQE3yGgtZBTZA3HI2TtQLZBNXyLAZD'

  provider_page_name = 'Hansi Merkurs Hutfabrik'
  provider_options   = {
    auth: {
      access_token: provider_key
    },
    sync: {
      page:     provider_page_name,
      group_id: 2,
      limit: 1,
    }
  }

  # add channel
  current = Channel.where( adapter: 'Facebook' )
  current.each(&:destroy)
  Channel.create(
    adapter:       'Facebook',
    area:          'Facebook::Inbound',
    options:       provider_options,
    active:        true,
    created_by_id: 1,
    updated_by_id: 1,
  )

  test 'pages' do

    provider_options_clone = provider_options

    provider_options_clone[:sync].delete(:page)

    facebook = Facebook.new( provider_options_clone )

    pages = facebook.pages

    page_found = false
    pages.each { |page|

      next if page[:name] != provider_page_name
      page_found = true
    }

    assert( page_found, "Page lookup for '#{provider_page_name}'" )
  end

  test 'feed post to ticket' do

    consumer_client = Koala::Facebook::API.new( consumer_key )
    feed_post       = "I've got an issue with my hat, serial number ##{rand(9999)}"

    facebook = Facebook.new( provider_options )

    post = consumer_client.put_wall_post(feed_post, {}, facebook.account['id'])

    # fetch check system account
    Channel.fetch

    # check if first article has been created
    article = Ticket::Article.find_by( message_id: post['id'] )

    assert( article, "article post '#{post['id']}' imported" )
    assert_equal( article.body, feed_post, 'ticket article inbound body' )
    assert_equal( 1, article.ticket.articles.count, 'ticket article inbound count' )
    assert_equal( feed_post, article.ticket.articles.last.body, 'ticket article inbound body' )

    post_comment = "Any updates yet? It's urgent. I love my hat."
    comment      = consumer_client.put_comment(post['id'], post_comment)

    # fetch check system account
    Channel.fetch

    # check if second article has been created
    article = Ticket::Article.find_by( message_id: comment['id'] )

    assert( article, "article comment '#{comment['id']}' imported" )
    assert_equal( article.body, post_comment, 'ticket article inbound body' )
    assert_equal( 2, article.ticket.articles.count, 'ticket article inbound count' )
    assert_equal( post_comment, article.ticket.articles.last.body, 'ticket article inbound body' )
  end

  test 'feed post and comment reply' do

    consumer_client = Koala::Facebook::API.new( consumer_key )
    feed_post       = "I've got an issue with my hat, serial number ##{rand(9999)}"

    facebook = Facebook.new( provider_options )

    post = consumer_client.put_wall_post(feed_post, {}, facebook.account['id'])

    # fetch check system account
    Channel.fetch

    # check if first article has been created
    article = Ticket::Article.find_by( message_id: post['id'] )

    reply_text = "What's your issue Bernd?"

    # reply via ticket
    outbound_article = Ticket::Article.create(
      ticket_id:     article.ticket.id,
      body:          reply_text,
      in_reply_to:   post['id'],
      type:          Ticket::Article::Type.find_by( name: 'facebook feed comment' ),
      sender:        Ticket::Article::Sender.find_by( name: 'Agent' ),
      internal:      false,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert( outbound_article, 'outbound article created' )
    assert_equal( outbound_article.ticket.articles.count, 2, 'ticket article outbound count' )

    post_comment = 'The peacock feather is fallen off.'
    comment      = consumer_client.put_comment(post['id'], post_comment)

    # fetch check system account
    Channel.fetch

    reply_text = "Please send it to our address and add the ticket number #{article.ticket.number}."

    # reply via ticket
    outbound_article = Ticket::Article.create(
      ticket_id:     article.ticket.id,
      body:          reply_text,
      in_reply_to:   comment['id'],
      type:          Ticket::Article::Type.find_by( name: 'facebook feed comment' ),
      sender:        Ticket::Article::Sender.find_by( name: 'Agent' ),
      internal:      false,
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert( outbound_article, 'outbound article created' )
    assert_equal( outbound_article.ticket.articles.count, 4, 'ticket article outbound count' )
  end
end
