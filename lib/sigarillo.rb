# Copyright (C) 2012-2015 Zammad Foundation, http://zammad-foundation.org/

require 'sigarillo_api'

class Sigarillo

  attr_accessor :client

=begin

check token and return bot attributes of token

  bot = Signal.check_token('token')

=end

  def self.check_token(api_url, token)

    api = SigarilloAPI.new(api_url, token)
    begin
      bot = api.fetch_self()
    rescue => e
      raise 'invalid api token: ' + e.message
    end
    bot
  end

=begin

create or update channel, store bot attributes and verify token

  channel = Signal.create_or_update_channel('token', params)

returns

  channel # instance of Channel

=end

  def self.create_or_update_channel(api_url, token, params, channel = nil)

    # verify token
    bot = Sigarillo.check_token(api_url, token)

    if !channel
      if Sigarillo.bot_duplicate?(bot['id'])
        raise 'Bot already exists!'
      end
    end

    if params[:group_id].blank?
      raise 'Group needed!'
    end

    group = Group.find_by(id: params[:group_id])
    if !group
      raise 'Group invalid!'
    end

    if !channel
      channel = Sigarillo.bot_by_bot_id(bot['id'])
      if !channel
        channel = Channel.new
      end
    end
    channel.area = 'Sigarillo::Account'
    channel.options = {
      adapter:   'sigarillo',
      bot:       {
        id:     bot['id'],
        number: bot['number'],
      },
      api_token: token,
      api_url:   api_url,
      welcome:   params[:welcome],
    }
    channel.group_id = group.id
    channel.active = true
    channel.save!
    channel
  end

=begin

check if bot already exists as channel

  success = Signal.bot_duplicate?(bot_id)

returns

  channel # instance of Channel

=end

  def self.bot_duplicate?(bot_id, channel_id = nil)
    Channel.where(area: 'Sigarillo::Account').each do |channel|
      next if !channel.options
      next if !channel.options[:bot]
      next if !channel.options[:bot][:id]
      next if channel.options[:bot][:id] != bot_id
      next if channel.id.to_s == channel_id.to_s

      return true
    end
    false
  end

=begin

get channel by bot_id

  channel = Signal.bot_by_bot_id(bot_id)

returns

  true|false

=end

  def self.bot_by_bot_id(bot_id)
    Channel.where(area: 'Sigarillo::Account').each do |channel|
      next if !channel.options
      next if !channel.options[:bot]
      next if !channel.options[:bot][:id]
      return channel if channel.options[:bot][:id].to_s == bot_id.to_s
    end
    nil
  end

=begin

  date = Sigarillo.timestamp_to_date('1543414973285')

returns

  2018-11-28T14:22:53.285Z

=end

  def self.timestamp_to_date(timestamp_str)
    Time.at(timestamp_str.to_i).utc.to_datetime
  end

  def self.message_id(message_raw)
    format('%<source>s@%<timestamp>s', source: message_raw['source'], timestamp: message_raw['timestamp'])
  end

=begin

  client = Signal.new('token')

=end

  def initialize(api_url, token)
    @token = token
    @api_url = api_url
    @api = SigarilloAPI.new(api_url, token)
  end

=begin

Fetch AND import messages for the bot

  client.fetch_messages(group_id, channel)

returns an updated ticket

=end

  def fetch_messages(group_id, channel)

    older_import = 0
    older_import_max = 20
    @api.fetch().each do |message_raw|
      Rails.logger.debug { 'processing message ' }
      Rails.logger.debug { message_raw.inspect }
      message = {
        source:     message_raw['source'],
        timestamp:  message_raw['timestamp'],
        created_at: Sigarillo.timestamp_to_date(message_raw['timestamp']),
        id:         Sigarillo.message_id(message_raw),
        message:    {
          body:       message_raw['message']['body'],
          profileKey: message_raw['message']['profileKey'],
        }
      }

      if (channel.created_at - 15.days) > message[:created_at] || older_import >= older_import_max
        older_import += 1
        Rails.logger.debug { "signal msg too old: #{message[:id]}/#{message[:created_at]}" }
        next
      end

      next if Ticket::Article.find_by(message_id: message[:id])

      to_group(message, group_id, channel)
    end
  end

=begin

  client.send_message(chat_id, 'some message')

=end

  def send_message(recipient, message)
    return if Rails.env.test?

    @api.send_message(recipient, message)
  end

  def user(number)
    {
      # id:         params[:message][:from][:id],
      id:       number,
      username: number,
      # first_name: params[:message][:from][:first_name],
      # last_name:  params[:message][:from][:last_name]
    }
  end

  def to_user(message)
    Rails.logger.debug { 'Create user from message...' }
    Rails.logger.debug { message.inspect }

    # do message_user lookup
    message_user = user(message[:source])

    # create or update user
    login = message_user[:username] || message_user[:id]

    auth = Authorization.find_by(uid: message[:source], provider: 'sigarillo')

    user_data = {
      login:  login,
      mobile: message[:source],
    }

    user = if auth
             User.find(auth.user_id)
           else
             User.where(mobile: message[:source]).order(:updated_at).first
           end
    if user
      user.update!(user_data)
    else
      user = User.create!(
        firstname: message[:source],
        mobile:    message[:source],
        note:      "Signal #{message_user[:username]}",
        active:    true,
        role_ids:  Role.signup_role_ids
      )
    end

    # create or update authorization
    auth_data = {
      uid:      message_user[:id],
      username: login,
      user_id:  user.id,
      provider: 'signal'
    }
    if auth
      auth.update!(auth_data)
    else
      Authorization.create(auth_data)
    end

    user
  end

  def to_ticket(message, user, group_id, channel)
    UserInfo.current_user_id = user.id

    Rails.logger.debug { 'Create ticket from message...' }
    Rails.logger.debug { message.inspect }
    Rails.logger.debug { user.inspect }
    Rails.logger.debug { group_id.inspect }

    # prepare title
    title = '-'
    if !message[:message][:body].nil?
      title = message[:message][:body]
    end
    if title.length > 60
      title = "#{title[0, 60]}..."
    end

    # find ticket or create one
    state_ids = Ticket::State.where(name: %w[closed merged removed]).pluck(:id)
    ticket = Ticket.where(customer_id: user.id).where.not(state_id: state_ids).order(:updated_at).first
    if ticket

      # check if title need to be updated
      if ticket.title == '-'
        ticket.title = title
      end
      new_state = Ticket::State.find_by(default_create: true)
      if ticket.state_id != new_state.id
        ticket.state = Ticket::State.find_by(default_follow_up: true)
      end
      ticket.save!
      return ticket
    end

    ticket = Ticket.new(
      group_id:    group_id,
      title:       title,
      state_id:    Ticket::State.find_by(default_create: true).id,
      priority_id: Ticket::Priority.find_by(default_create: true).id,
      customer_id: user.id,
      preferences: {
        channel_id: channel.id,
        sigarillo:  {
          bot_id:  channel.options[:bot][:id],
          chat_id: message[:source]
        }
      }
    )
    ticket.save!
    ticket
  end

  def to_article(message, user, ticket, channel)

    Rails.logger.debug { 'Create article from message...' }
    Rails.logger.debug { message.inspect }
    Rails.logger.debug { user.inspect }
    Rails.logger.debug { ticket.inspect }

    UserInfo.current_user_id = user.id

    article = Ticket::Article.new(
      from:         message[:source],
      to:           channel[:options][:bot][:number],
      body:         message[:message][:body],
      content_type: 'text/plain',
      message_id:   "sigarillo.#{message[:id]}",
      ticket_id:    ticket.id,
      type_id:      Ticket::Article::Type.find_by(name: 'signal personal-message').id,
      sender_id:    Ticket::Article::Sender.find_by(name: 'Customer').id,
      internal:     false,
      preferences:  {
        sigarillo: {
          timestamp:  message[:timestamp],
          message_id: message[:id],
          from:       message[:source],
        }
      }
    )

    # TODO: attachments
    # TODO voice
    # TODO emojis
    #
    if message[:message][:body]
      Rails.logger.debug { article.inspect }
      article.save!
      return article
    end
    raise 'invalid action'
  end

  def to_group(message, group_id, channel)
    # begin import
    Rails.logger.debug { 'sigarillo import message' }

    # TODO: handle messages in group chats

    return if Ticket::Article.find_by(message_id: message[:id])

    ticket = nil
    # use transaction
    Transaction.execute(reset_user_id: true) do
      user = to_user(message)
      ticket = to_ticket(message, user, group_id, channel)
      to_article(message, user, ticket, channel)
    end

    ticket
  end

  def from_article(article)
    # sends a message from a zammad article

    Rails.logger.debug { "Create signal personal message from article to '#{article[:to]}'..." }

    @api.send_message(article[:to], article[:body])
  end

  def download_file(file_id)
    # TODO: attachments
  end

end
