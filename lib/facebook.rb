# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Facebook

  attr_accessor :client, :account

=begin

  client = Facebook.new('user_or_page_access_token')

=end

  def initialize(access_token)
    connect(access_token)
  end

=begin

reconnect with other access_token

  client.connect('user_or_page_access_token')

=end

  def connect(access_token)
    @client = Koala::Facebook::API.new(access_token)
  end

=begin

disconnect client

  client.disconnect

=end

  def disconnect
    return if !@client

    @client = nil
  end

=begin

get pages of user

  pages = client.pages

result

  [
    {
      id: '12345',
      name: 'Some Page Name',
      access_token, 'some_access_token_for_page',
    },
  ]

=end

  def pages
    pages = []
    @client.get_connections('me', 'accounts').each do |page|
      pages.push(
        id:           page['id'],
        name:         page['name'],
        access_token: page['access_token'],
      )
    end
    pages
  end

=begin

get current user

  pages = current_user

result

  {
    'id' => '1234567890123456',
    'name' => 'Page/User Name',
    'access_token' => 'some_acces_token'
  }

=end

  def current_user
    @client.get_object('me')
  end

=begin

get user of comment/post

  pages = user(comment_or_post)

result

???

=end

  def user(item)
    return if !item['from']
    return if !item['from']['id']

    cache_key = "FB:User:Lookup:#{item['from']['id']}"
    cache = Cache.read(cache_key)
    return cache if cache

    begin
      result = @client.get_object(item['from']['id'], fields: 'first_name,last_name,email')
    rescue
      result = @client.get_object(item['from']['id'], fields: 'name')
    end
    if result
      Cache.write(cache_key, result, { expires_in: 15.minutes })
    end
    result
  end

  def to_user(item)
    Rails.logger.debug { 'Create user from item...' }
    Rails.logger.debug { item.inspect }

    # do item_user lookup
    item_user = user(item)
    return if !item_user

    auth = Authorization.find_by(uid: item_user['id'], provider: 'facebook')

    # create or update user
    user_data = {
      image_source: "https://graph.facebook.com/#{item_user['id']}/picture?type=large",
    }
    if auth
      user = User.find(auth.user_id)
      user.update!(user_data)
    else
      user_data[:login] = item_user['id']
      if item_user['first_name'] && item_user['last_name']
        user_data[:firstname] = item_user['first_name']
        user_data[:lastname]  = item_user['last_name']
      else
        user_data[:firstname] = item_user['name']
      end
      user_data[:active]   = true
      user_data[:role_ids] = Role.signup_role_ids

      user = User.create(user_data)
    end

    if user_data[:image_source]
      avatar = Avatar.add(
        object:        'User',
        o_id:          user.id,
        url:           user_data[:image_source],
        source:        'facebook',
        deletable:     true,
        updated_by_id: user.id,
        created_by_id: user.id,
      )

      # update user link
      if avatar && user.image != avatar.store_hash
        user.image = avatar.store_hash
        user.save
      end
    end

    # create authorization
    if !auth
      auth_data = {
        uid:      item_user['id'],
        username: item_user['id'],
        user_id:  user.id,
        provider: 'facebook'
      }
      Authorization.create(auth_data)
    end
    UserInfo.current_user_id = user.id
    user
  end

  def to_ticket(post, group_id, channel, page)

    Rails.logger.debug { 'Create ticket from post...' }
    Rails.logger.debug { post.inspect }
    Rails.logger.debug { group_id.inspect }

    user = to_user(post)
    return if !user

    # prepare title
    title = post['message']
    if title.length > 80
      title = "#{title[0, 80]}..."
    end

    state = get_state(page, post)
    Ticket.create!(
      customer_id: user.id,
      title:       title,
      group_id:    group_id,
      state:       state,
      priority:    Ticket::Priority.find_by(name: '2 normal'),
      preferences: {
        channel_id:           channel.id,
        channel_fb_object_id: page['id'],
        facebook:             {
          permalink_url: post['permalink_url'],
        }
      },
    )
  end

  def to_article(post, ticket, page)

    Rails.logger.debug { 'Create article from post...' }
    Rails.logger.debug { post.inspect }
    Rails.logger.debug { ticket.inspect }

    user = to_user(post)
    return if !user

    to = nil
    if post['to'] && post['to']['data']
      post['to']['data'].each do |to_entry|
        if to
          to += ', '
        else
          to = ''
        end
        to += to_entry['name']
      end
    end

    feed_post = {
      from:       post['from']['name'],
      to:         to,
      body:       post['message'],
      message_id: post['id'],
      type_id:    Ticket::Article::Type.find_by(name: 'facebook feed post').id,
    }

    articles = []
    articles.push(feed_post)

    if post['comments'] && post['comments']['data']
      articles += nested_comments(post['comments']['data'], post['id'])
    end

    base_url = nil
    if ticket.preferences['facebook'] && ticket.preferences['facebook']['permalink_url']
      base_url = ticket.preferences['facebook']['permalink_url']
    end

    articles.each do |article|
      next if Ticket::Article.exists?(message_id: article[:message_id])

      # set ticket state to open if not new
      ticket_state = get_state(page, post, ticket)
      if ticket_state.name != ticket.state.name
        ticket.state = ticket_state
        ticket.save!
      end

      links = []
      if base_url
        url = base_url
        realtive_id = article[:message_id].split('_')[1]
        if realtive_id
          url += "?comment_id=#{realtive_id}"
        end
        links = [
          {
            url:    url,
            target: '_blank',
            name:   'on Facebook',
          },
        ]
      end

      article = {
        #to:        @account['name'],
        ticket_id:     ticket.id,
        internal:      false,
        sender_id:     Ticket::Article::Sender.lookup(name: 'Customer').id,
        created_by_id: 1,
        updated_by_id: 1,
        preferences:   {
          links: links,
        },
      }.merge(article)
      Ticket::Article.create(article)
    end
  end

  def to_group(post, group_id, channel, page)
    Rails.logger.debug { 'import post' }
    return if !post['message']

    ticket = nil

    # use transaction
    Transaction.execute(reset_user_id: true) do
      existing_article = Ticket::Article.find_by(message_id: post['id'])
      ticket = if existing_article
                 existing_article.ticket
               else
                 to_ticket(post, group_id, channel, page)
               end
      to_article(post, ticket, page)
    end

    ticket
  end

  def from_article(article)
    post = nil
    if article[:type] != 'facebook feed comment'
      raise "Can't handle unknown facebook article type '#{article[:type]}'."
    end

    Rails.logger.debug { 'Create feed comment from article...' }
    post = @client.put_comment(article[:in_reply_to], article[:body])
    Rails.logger.debug { post.inspect }
    @client.get_object(post['id'])
  end

  private

  def get_state(page, post, ticket = nil)

    # no changes in post is from page user it self
    if post['from'] && post['from']['id'].to_s == page['id'].to_s
      if !ticket
        return Ticket::State.find_by(name: 'closed')
      end

      return ticket.state
    end

    state = Ticket::State.find_by(default_create: true)
    return state if !ticket

    return ticket.state if ticket.state_id == state.id

    Ticket::State.find_by(default_follow_up: true)
  end

  def access_token_for_page(lookup)
    access_token = nil
    pages.each do |page|
      next if !lookup[:page_id] && !lookup[:page]
      next if lookup[:page_id] && lookup[:page_id].to_s != page[:id]
      next if lookup[:page] && lookup[:page] != page[:name]

      access_token = page[:access_token]
      break
    end
    access_token
  end

  def nested_comments(comments, in_reply_to)

    Rails.logger.debug { 'Fetching nested comments...' }
    Rails.logger.debug { comments.inspect }

    result = []
    return result if comments.blank?

    comments.each do |comment|
      user = to_user(comment)
      next if !user

      article_data = {
        from:        "#{user.firstname} #{user.lastname}",
        body:        comment['message'],
        message_id:  comment['id'],
        type_id:     Ticket::Article::Type.find_by(name: 'facebook feed comment').id,
        in_reply_to: in_reply_to
      }
      result.push(article_data)
      sub_comments = @client.get_object("#{comment['id']}/comments", fields: 'id,from,to,message,created_time')
      sub_articles = nested_comments(sub_comments, comment['id'])
      result += sub_articles
    end

    result
  end

end
