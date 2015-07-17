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

  def user(post)

    return if !post['from']
    return if !post['from']['id']
    return if !post['from']['name']

    return if !post['from']['id'] == @account['id']

    @client.get_object( post['from']['id'] )
  end

  def to_user(post)

    Rails.logger.debug 'Create user from post...'
    Rails.logger.debug post.inspect

    # do post_user lookup
    post_user = user(post)

    return if !post_user

    auth = Authorization.find_by( uid: post_user['id'], provider: 'facebook' )

    # create or update user
    user_data = {
      login:        post_user['id'], # TODO
      firstname:    post_user['first_name'] || post_user['name'],
      lastname:     post_user['last_name'] || '',
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
      uid:      post_user['id'],
      username: post_user['id'], # TODO
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

    if post['comments']
      post['comments']['data'].each { |comment|

        user = to_user(comment)

        next if !user

        post_comment = {
          from:         "#{user.firstname} #{user.lastname}",
          body:       comment['message'],
          message_id: comment['id'],
          type_id:    Ticket::Article::Type.find_by( name: 'facebook feed comment' ).id,
        }
        articles.push( post_comment )

        # TODO: sub-comments
        # comment_data = @client.get_object( comment['id'] )
      }
    end

    inverted_articles = articles.reverse

    inverted_articles.each { |article|

      break if Ticket::Article.find_by( message_id: article[:message_id] )

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
end
