# Copyright (C) 2012-2015 Zammad Foundation, http://zammad-foundation.org/

require 'koala'

class Facebook

  attr_accessor :client, :account

  def initialize(options)

    connect( options[:auth][:access_token] )

    page_access_token = access_token_for_page( options[:sync] )

    if page_access_token
      connect( page_access_token )
    end

    @account = client.get_object('me')
  end

  def connect(access_token)
    @client = Koala::Facebook::API.new( access_token )
  end

  def disconnect

    return if !@client

    @client = nil
  end

  def pages
    pages = []
    @client.get_connections('me', 'accounts').each { |page|
      pages.push({
                   id:           page['id'],
                   name:         page['name'],
                   access_token: page['access_token'],
                 })
    }
    pages
  end

  def user(item)

    return if !item['from']
    return if !item['from']['id']
    return if !item['from']['name']

    return if item['from']['id'] == @account['id']

    @client.get_object( item['from']['id'] )
  end

  def to_user(item)

    Rails.logger.debug 'Create user from item...'
    Rails.logger.debug item.inspect

    # do item_user lookup
    item_user = user(item)

    return if !item_user

    auth = Authorization.find_by( uid: item_user['id'], provider: 'facebook' )

    # create or update user
    user_data = {
      login:        item_user['id'], # TODO
      firstname:    item_user['first_name'] || item_user['name'],
      lastname:     item_user['last_name'] || '',
      email:        '',
      password:     '',
      # TODO: image_source: '',
      # TODO: note:         '',
      active:       true,
      roles:        Role.where( name: 'Customer' ),
    }
    if auth
      user_data[:id] = auth.user_id
    end
    user = User.create_or_update( user_data )

    # create or update authorization
    auth_data = {
      uid:      item_user['id'],
      username: item_user['id'], # TODO
      user_id:  user.id,
      provider: 'facebook'
    }
    if auth
      auth.update_attributes( auth_data )
    else
      Authorization.new( auth_data )
    end

    UserInfo.current_user_id = user.id

    user
  end

  def to_ticket(post, group_id)

    Rails.logger.debug 'Create ticket from post...'
    Rails.logger.debug post.inspect
    Rails.logger.debug group_id.inspect

    user = to_user(post)
    return if !user

    Ticket.create(
      customer_id: user.id,
      title:       "#{post['message'][0, 37]}...",
      group_id:    group_id,
      state:       Ticket::State.find_by( name: 'new' ),
      priority:    Ticket::Priority.find_by( name: '2 normal' ),
    )
  end

  def to_article(post, ticket)

    Rails.logger.debug 'Create article from post...'
    Rails.logger.debug post.inspect
    Rails.logger.debug ticket.inspect

    # set ticket state to open if not new
    if ticket.state.name != 'new'
      ticket.state = Ticket::State.find_by( name: 'open' )
      ticket.save
    end

    user = to_user(post)
    return if !user

    feed_post = {
      from:       "#{user.firstname} #{user.lastname}",
      body:       post['message'],
      message_id: post['id'],
      type_id:    Ticket::Article::Type.find_by( name: 'facebook feed post' ).id,
    }
    articles = []
    articles.push( feed_post )

    if post['comments'] && post['comments']['data']
      articles += nested_comments( post['comments']['data'], post['id'] )
    end

    articles.each { |article|

      next if Ticket::Article.find_by( message_id: article[:message_id] )

      article = {
        to:        @account['name'],
        ticket_id: ticket.id,
        internal:  false,
        sender_id: Ticket::Article::Sender.lookup( name: 'Customer' ).id,
        created_by_id: 1,
        updated_by_id: 1,
      }.merge( article )

      Ticket::Article.create( article )
    }
  end

  def to_group(post, group_id)

    Rails.logger.debug 'import post'

    ticket = nil
    # use transaction
    ActiveRecord::Base.transaction do

      UserInfo.current_user_id = 1

      existing_article = Ticket::Article.find_by( message_id: post['id'] )
      if existing_article
        ticket = existing_article.ticket
      else
        ticket = to_ticket(post, group_id)
        return if !ticket
      end

      to_article(post, ticket)

      # execute ticket events
      Observer::Ticket::Notification.transaction
    end

    ticket
  end

  def from_article(article)

    post = nil
    if article[:type] == 'facebook feed comment'

      Rails.logger.debug 'Create feed comment from article...'

      post = @client.put_comment(article[:in_reply_to], article[:body])
    else
      fail "Can't handle unknown facebook article type '#{article[:type]}'."
    end

    Rails.logger.debug post.inspect
    @client.get_object( post['id'] )
  end

  private

  def access_token_for_page(lookup)

    access_token = nil
    pages.each { |page|

      next if !lookup[:page_id] && !lookup[:page]
      next if lookup[:page_id] && lookup[:page_id].to_s != page[:id]
      next if lookup[:page] && lookup[:page] != page[:name]

      access_token = page[:access_token]

      break
    }

    access_token
  end

  def nested_comments(comments, in_reply_to)

    Rails.logger.debug 'Fetching nested comments...'
    Rails.logger.debug comments.inspect

    result = []
    return result if comments.empty?

    comments.each { |comment|

      user = to_user(comment)

      next if !user

      article_data = {
        from:         "#{user.firstname} #{user.lastname}",
        body:       comment['message'],
        message_id: comment['id'],
        type_id:    Ticket::Article::Type.find_by( name: 'facebook feed comment' ).id,
        in_reply_to: in_reply_to
      }
      result.push( article_data )

      sub_comments = @client.get_object( "#{comment['id']}/comments" )

      sub_articles = nested_comments(sub_comments, comment['id'])

      result += sub_articles
    }

    result
  end
end
