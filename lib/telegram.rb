# Copyright (C) 2012-2015 Zammad Foundation, http://zammad-foundation.org/

class Telegram

  attr_accessor :client

=begin

check token and return bot attributes of token

  bot = Telegram.check_token('token')

=end

  def self.check_token(token)
    api = TelegramAPI.new(token)
    begin
      bot = api.getMe()
    rescue
      raise 'invalid api token'
    end
    bot
  end

=begin

set webhool for bot

  success = Telegram.set_webhook('token', callback_url)

returns

  true|false

=end

  def self.set_webhook(token, callback_url)
    if callback_url =~ %r{^http://}i
      raise 'webhook url need to start with https://, you use http://'
    end
    api = TelegramAPI.new(token)
    begin
      api.setWebhook(callback_url)
    rescue
      raise 'Unable to set webhook at Telegram, seems to be a invalid url.'
    end
    true
  end

=begin

create or update channel, store bot attributes and verify token

  channel = Telegram.create_or_update_channel('token', params)

returns

  channel # instance of Channel

=end

  def self.create_or_update_channel(token, params, channel = nil)

    # verify token
    bot = Telegram.check_token(token)

    if !channel
      if Telegram.bot_duplicate?(bot['id'])
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

    # generate randam callback token
    callback_token = if Rails.env.test?
                       'callback_token'
                     else
                       SecureRandom.urlsafe_base64(10)
                     end

    # set webhook / callback url for this bot @ telegram
    callback_url = "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/api/v1/channels_telegram_webhook/#{callback_token}?bid=#{bot['id']}"
    Telegram.set_webhook(token, callback_url)

    if !channel
      channel = Telegram.bot_by_bot_id(bot['id'])
      if !channel
        channel = Channel.new
      end
    end
    channel.area = 'Telegram::Bot'
    channel.options = {
      bot: {
        id: bot['id'],
        username: bot['username'],
        first_name: bot['first_name'],
        last_name: bot['last_name'],
      },
      callback_token: callback_token,
      callback_url: callback_url,
      api_token: token,
      welcome: params[:welcome],
    }
    channel.group_id = group.id
    channel.active = true
    channel.save!
    channel
  end

=begin

check if bot already exists as channel

  success = Telegram.bot_duplicate?(bot_id)

returns

  channel # instance of Channel

=end

  def self.bot_duplicate?(bot_id, channel_id = nil)
    Channel.where(area: 'Telegram::Bot').each { |channel|
      next if !channel.options
      next if !channel.options[:bot]
      next if !channel.options[:bot][:id]
      next if channel.options[:bot][:id] != bot_id
      next if channel.id.to_s == channel_id.to_s
      return true
    }
    false
  end

=begin

get channel by bot_id

  channel = Telegram.bot_by_bot_id(bot_id)

returns

  true|false

=end

  def self.bot_by_bot_id(bot_id)
    Channel.where(area: 'Telegram::Bot').each { |channel|
      next if !channel.options
      next if !channel.options[:bot]
      next if !channel.options[:bot][:id]
      return channel if channel.options[:bot][:id].to_s == bot_id.to_s
    }
    nil
  end

=begin

generate message_id for message

  message_id = Telegram.message_id(message)

returns

  message_id # 123456@telegram

=end

  def self.message_id(params)
    message_id = nil
    [:message, :edited_message].each { |key|
      next if !params[key]
      next if !params[key][:message_id]
      message_id = params[key][:message_id]
      break
    }
    if message_id
      [:message, :edited_message].each { |key|
        next if !params[key]
        next if !params[key][:chat]
        next if !params[key][:chat][:id]
        message_id = "#{message_id}.#{params[key][:chat][:id]}"
      }
    end
    if !message_id
      message_id = params[:update_id]
    end
    "#{message_id}@telegram"
  end

=begin

  client = Telegram.new('token')

=end

  def initialize(token)
    @token = token
    @api = TelegramAPI.new(token)
  end

=begin

  client.message(chat_id, 'some message')

=end

  def message(chat_id, message)
    return if Rails.env.test?
    @api.sendMessage(chat_id, message)
  end

  def user(params)
    {
      id:         params[:message][:from][:id],
      username:   params[:message][:from][:username],
      first_name: params[:message][:from][:first_name],
      last_name:  params[:message][:from][:last_name]
    }
  end

  def to_user(params)
    Rails.logger.debug 'Create user from message...'
    Rails.logger.debug params.inspect

    # do message_user lookup
    message_user = user(params)

    auth = Authorization.find_by(uid: message_user[:id], provider: 'telegram')

    # create or update user
    login = message_user[:username] || message_user[:id]
    user_data = {
      login: login,
      firstname: message_user[:first_name],
      lastname: message_user[:last_name],
    }
    if auth
      user = User.find(auth.user_id)
      user.update_attributes(user_data)
    else
      if message_user[:username]
        user_data[:note] = "Telegram @#{message_user[:username]}"
      end
      user_data[:active]   = true
      user_data[:role_ids] = Role.signup_role_ids
      user                 = User.create(user_data)
    end

    # create or update authorization
    auth_data = {
      uid:      message_user[:id],
      username: login,
      user_id:  user.id,
      provider: 'telegram'
    }
    if auth
      auth.update_attributes(auth_data)
    else
      Authorization.create(auth_data)
    end

    user
  end

  def to_ticket(params, user, group_id, channel)
    UserInfo.current_user_id = user.id

    Rails.logger.debug 'Create ticket from message...'
    Rails.logger.debug params.inspect
    Rails.logger.debug user.inspect
    Rails.logger.debug group_id.inspect

    # prepare title
    title = '-'
    [:text, :caption].each { |area|
      next if !params[:message]
      next if !params[:message][area]
      title = params[:message][area]
      break
    }
    if title == '-'
      [:sticker, :photo, :document, :voice].each { |area|
        begin
          next if !params[:message]
          next if !params[:message][area]
          next if !params[:message][area][:emoji]
          title = params[:message][area][:emoji]
          break
        rescue
          # just go ahead
          title
        end
      }
    end
    if title.length > 60
      title = "#{title[0, 60]}..."
    end

    # find ticket or create one
    state_ids = Ticket::State.where(name: %w(closed merged removed)).pluck(:id)
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
      group_id: group_id,
      title: title,
      state_id: Ticket::State.find_by(default_create: true).id,
      priority_id: Ticket::Priority.find_by(default_create: true).id,
      customer_id: user.id,
      preferences: {
        channel_id: channel.id,
        telegram: {
          bid: params['bid'],
          chat_id: params[:message][:chat][:id]
        }
      },
    )
    ticket.save!
    ticket
  end

  def to_article(params, user, ticket, channel, article = nil)

    if article
      Rails.logger.debug 'Update article from message...'
    else
      Rails.logger.debug 'Create article from message...'
    end
    Rails.logger.debug params.inspect
    Rails.logger.debug user.inspect
    Rails.logger.debug ticket.inspect

    UserInfo.current_user_id = user.id

    if article
      article.preferences[:edited_message] = {
        message: {
          created_at: params[:message][:date],
          message_id: params[:message][:message_id],
          from: params[:message][:from],
        },
        update_id: params[:update_id],
      }
    else
      article = Ticket::Article.new(
        ticket_id: ticket.id,
        type_id: Ticket::Article::Type.find_by(name: 'telegram personal-message').id,
        sender_id: Ticket::Article::Sender.find_by(name: 'Customer').id,
        from: user(params)[:username],
        to: "@#{channel[:options][:bot][:username]}",
        message_id: Telegram.message_id(params),
        internal: false,
        preferences: {
          message: {
            created_at: params[:message][:date],
            message_id: params[:message][:message_id],
            from: params[:message][:from],
          },
          update_id: params[:update_id],
        }
      )
    end

    # add article
    if params[:message][:photo]

      # find photo with best resolution for us
      photo = nil
      max_width = 650 * 2
      last_width = 0
      last_height = 0
      params[:message][:photo].each { |file|
        if !photo
          photo = file
          last_width = file['width'].to_i
          last_height = file['height'].to_i
        end
        next unless file['width'].to_i < max_width && last_width < file['width'].to_i
        photo = file
        last_width = file['width'].to_i
        last_height = file['height'].to_i
      }
      if last_width > 650
        last_width = (last_width / 2).to_i
        last_height = (last_height / 2).to_i
      end

      # download image
      result = download_file(photo['file_id'])
      if !result.success? || !result.body
        raise "Unable for download image from telegram: #{result.code}"
      end
      body = "<img style=\"width:#{last_width}px;height:#{last_height}px;\" src=\"data:image/png;base64,#{Base64.strict_encode64(result.body)}\">"
      if params[:message][:caption]
        body += "<br>#{params[:message][:caption].text2html}"
      end
      article.content_type = 'text/html'
      article.body = body
      article.save!
      return article
    end

    # add document
    if params[:message][:document]
      thumb = params[:message][:document][:thumb]
      body = '&nbsp;'
      if thumb
        width = thumb[:width]
        height = thumb[:height]
        result = download_file(thumb['file_id'])
        if !result.success? || !result.body
          raise "Unable for download image from telegram: #{result.code}"
        end
        body = "<img style=\"width:#{width}px;height:#{height}px;\" src=\"data:image/png;base64,#{Base64.strict_encode64(result.body)}\">"
      end
      document_result = download_file(params[:message][:document][:file_id])
      article.content_type = 'text/html'
      article.body = body
      article.save!
      Store.remove(
        object: 'Ticket::Article',
        o_id: article.id,
      )
      Store.add(
        object: 'Ticket::Article',
        o_id: article.id,
        data: document_result.body,
        filename: params[:message][:document][:file_name],
        preferences: {
          'Mime-Type' => params[:message][:document][:mime_type],
        },
      )
      return article
    end

    # voice
    if params[:message][:voice]
      body = '&nbsp;'
      if params[:message][:caption]
        body = "<br>#{params[:message][:caption].text2html}"
      end
      document_result = download_file(params[:message][:voice][:file_id])
      article.content_type = 'text/html'
      article.body = body
      article.save!
      Store.remove(
        object: 'Ticket::Article',
        o_id: article.id,
      )
      Store.add(
        object: 'Ticket::Article',
        o_id: article.id,
        data: document_result.body,
        filename: params[:message][:voice][:file_path] || 'audio',
        preferences: {
          'Mime-Type' => params[:message][:voice][:mime_type],
        },
      )
      return article
    end

    if params[:message][:sticker]
      emoji = params[:message][:sticker][:emoji]
      thumb = params[:message][:sticker][:thumb]
      body = '&nbsp;'
      if thumb
        width = thumb[:width]
        height = thumb[:height]
        result = download_file(thumb['file_id'])
        if !result.success? || !result.body
          raise "Unable for download image from telegram: #{result.code}"
        end
        body = "<img style=\"width:#{width}px;height:#{height}px;\" src=\"data:image/png;base64,#{Base64.strict_encode64(result.body)}\">"
        article.content_type = 'text/html'
      elsif emoji
        article.content_type = 'text/plain'
        body = emoji
      end
      article.body = body
      article.save!

      if params[:message][:sticker][:file_id]
        document_result = download_file(params[:message][:sticker][:file_id])
        Store.remove(
          object: 'Ticket::Article',
          o_id: article.id,
        )
        Store.add(
          object: 'Ticket::Article',
          o_id: article.id,
          data: document_result.body,
          filename: params[:message][:sticker][:file_name] || 'sticker',
          preferences: {
            'Mime-Type' => params[:message][:sticker][:mime_type],
          },
        )
      end
      return article
    end

    # text
    if params[:message][:text]
      article.content_type = 'text/plain'
      article.body = params[:message][:text]
      article.save!
      return article
    end
    raise 'invalid action'
  end

  def to_group(params, group_id, channel)
    Rails.logger.debug 'import message'

    # prevent multible update
    if !params[:edited_message]
      return if Ticket::Article.find_by(message_id: Telegram.message_id(params))
    end

    # update article
    if params[:edited_message]
      article = Ticket::Article.find_by(message_id: Telegram.message_id(params))
      return if !article
      params[:message] = params[:edited_message]
      user = to_user(params)
      to_article(params, user, article.ticket, channel, article)
      return article
    end

    # send welcome message and don't create ticket
    text = params[:message][:text]
    if text.present? && text =~ %r{^/start}
      message(params[:message][:chat][:id], channel.options[:welcome] || 'You are welcome! Just ask me something!')
      return

    # find ticket and close it
    elsif text.present? && text =~ %r{^/end}
      user = to_user(params)
      ticket = Ticket.where(customer_id: user.id).order(:updated_at).first
      ticket.state = Ticket::State.find_by(name: 'closed')
      ticket.save!
      return
    end

    ticket = nil

    # use transaction
    Transaction.execute(reset_user_id: true) do
      user = to_user(params)
      ticket = to_ticket(params, user, group_id, channel)
      to_article(params, user, ticket, channel)
    end

    ticket
  end

  def from_article(article)

    message = nil
    Rails.logger.debug "Create telegram personal message from article to '#{article[:to]}'..."

    message = {}
    # TODO: create telegram message here

    Rails.logger.debug message.inspect
    message
  end

  def get_state(channel, telegram_update, ticket = nil)
    message = telegram_update['message']
    message_user = user(message)

    # no changes in post is from page user it self
    if channel.options[:bot][:id].to_s == message_user[:id].to_s
      if !ticket
        return Ticket::State.find_by(name: 'closed') if !ticket
      end
      return ticket.state
    end

    state = Ticket::State.find_by(default_create: true)
    return state if !ticket
    return ticket.state if ticket.state.id == state.id
    Ticket::State.find_by(default_follow_up: true)
  end

  def download_file(file_id)
    document = @api.getFile(file_id)
    url = "https://api.telegram.org/file/bot#{@token}/#{document['file_path']}"
    UserAgent.get(
      url,
      {},
      {
        open_timeout: 20,
        read_timeout: 40,
      },
    )
  end

end
