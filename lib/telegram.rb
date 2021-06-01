# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
      raise Exceptions::UnprocessableEntity, 'invalid api token'
    end
    bot
  end

=begin

set webhook for bot

  success = Telegram.set_webhook('token', callback_url)

returns

  true|false

=end

  def self.set_webhook(token, callback_url)
    if callback_url.match?(%r{^http://}i)
      raise Exceptions::UnprocessableEntity, 'webhook url need to start with https://, you use http://'
    end

    api = TelegramAPI.new(token)
    begin
      api.setWebhook(callback_url)
    rescue
      raise Exceptions::UnprocessableEntity, 'Unable to set webhook at Telegram, seems to be a invalid url.'
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

    if !channel && Telegram.bot_duplicate?(bot['id'])
      raise Exceptions::UnprocessableEntity, 'Bot already exists!'
    end

    if params[:group_id].blank?
      raise Exceptions::UnprocessableEntity, 'Group needed!'
    end

    group = Group.find_by(id: params[:group_id])
    if !group
      raise Exceptions::UnprocessableEntity, 'Group invalid!'
    end

    # generate random callback token
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
      bot:            {
        id:         bot['id'],
        username:   bot['username'],
        first_name: bot['first_name'],
        last_name:  bot['last_name'],
      },
      callback_token: callback_token,
      callback_url:   callback_url,
      api_token:      token,
      welcome:        params[:welcome],
      goodbye:        params[:goodbye],
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
    Channel.where(area: 'Telegram::Bot').each do |channel|
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

  channel = Telegram.bot_by_bot_id(bot_id)

returns

  true|false

=end

  def self.bot_by_bot_id(bot_id)
    Channel.where(area: 'Telegram::Bot').each do |channel|
      next if !channel.options
      next if !channel.options[:bot]
      next if !channel.options[:bot][:id]
      return channel if channel.options[:bot][:id].to_s == bot_id.to_s
    end
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
    %i[message edited_message].each do |key|
      next if !params[key]
      next if !params[key][:message_id]

      message_id = params[key][:message_id]
      break
    end
    if message_id
      %i[message edited_message].each do |key|
        next if !params[key]
        next if !params[key][:chat]
        next if !params[key][:chat][:id]

        message_id = "#{message_id}.#{params[key][:chat][:id]}"
      end
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

  client.message(chat_id, 'some message', language_code)

=end

  def message(chat_id, message, language_code = 'en')
    return if Rails.env.test?

    locale = Locale.find_by(alias: language_code)
    if !locale
      locale = Locale.where('locale LIKE :prefix', prefix: "#{language_code}%").first
    end

    if locale
      message = Translation.translate(locale[:locale], message)
    end

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
    Rails.logger.debug { 'Create user from message...' }
    Rails.logger.debug { params.inspect }

    # do message_user lookup
    message_user = user(params)

    auth = Authorization.find_by(uid: message_user[:id], provider: 'telegram')

    # create or update user
    login = message_user[:username] || message_user[:id]
    user_data = {
      login:     login,
      firstname: message_user[:first_name],
      lastname:  message_user[:last_name],
    }
    if auth
      user = User.find(auth.user_id)
      user.update!(user_data)
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
      auth.update!(auth_data)
    else
      Authorization.create(auth_data)
    end

    user
  end

  def to_ticket(params, user, group_id, channel)
    UserInfo.current_user_id = user.id

    Rails.logger.debug { 'Create ticket from message...' }
    Rails.logger.debug { params.inspect }
    Rails.logger.debug { user.inspect }
    Rails.logger.debug { group_id.inspect }

    # prepare title
    title = '-'
    %i[text caption].each do |area|
      next if !params[:message]
      next if !params[:message][area]

      title = params[:message][area]
      break
    end
    if title == '-'
      %i[sticker photo document voice].each do |area|

        next if !params[:message]
        next if !params[:message][area]
        next if !params[:message][area][:emoji]

        title = params[:message][area][:emoji]
        break
      rescue
        # just go ahead
        title

      end
    end
    if title.length > 60
      title = "#{title[0, 60]}..."
    end

    # find ticket or create one
    state_ids        = Ticket::State.where(name: %w[closed merged removed]).pluck(:id)
    possible_tickets = Ticket.where(customer_id: user.id).where.not(state_id: state_ids).order(:updated_at)
    ticket           = possible_tickets.find_each.find { |possible_ticket| possible_ticket.preferences[:channel_id] == channel.id }

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
        telegram:   {
          bid:     params['bid'],
          chat_id: params[:message][:chat][:id]
        }
      },
    )
    ticket.save!
    ticket
  end

  def to_article(params, user, ticket, channel, article = nil)

    if article
      Rails.logger.debug { 'Update article from message...' }
    else
      Rails.logger.debug { 'Create article from message...' }
    end
    Rails.logger.debug { params.inspect }
    Rails.logger.debug { user.inspect }
    Rails.logger.debug { ticket.inspect }

    UserInfo.current_user_id = user.id

    if article
      article.preferences[:edited_message] = {
        message:   {
          created_at: params[:message][:date],
          message_id: params[:message][:message_id],
          from:       params[:message][:from],
        },
        update_id: params[:update_id],
      }
    else
      article = Ticket::Article.new(
        ticket_id:   ticket.id,
        type_id:     Ticket::Article::Type.find_by(name: 'telegram personal-message').id,
        sender_id:   Ticket::Article::Sender.find_by(name: 'Customer').id,
        from:        user(params)[:username],
        to:          "@#{channel[:options][:bot][:username]}",
        message_id:  Telegram.message_id(params),
        internal:    false,
        preferences: {
          message:   {
            created_at: params[:message][:date],
            message_id: params[:message][:message_id],
            from:       params[:message][:from],
          },
          update_id: params[:update_id],
        }
      )
    end

    # add photo
    if params[:message][:photo]

      # find photo with best resolution for us
      photo       = nil
      max_width   = 650 * 2
      last_width  = 0
      last_height = 0

      params[:message][:photo].each do |file|
        if !photo
          photo = file
          last_width = file['width'].to_i
          last_height = file['height'].to_i
        end
        next if file['width'].to_i >= max_width || file['width'].to_i <= last_width

        photo       = file
        last_width  = file['width'].to_i
        last_height = file['height'].to_i
      end
      if last_width > 650
        last_width = (last_width / 2).to_i
        last_height = (last_height / 2).to_i
      end

      # download photo
      photo_result = get_file(params, photo)
      body = "<img style=\"width:#{last_width}px;height:#{last_height}px;\" src=\"data:image/png;base64,#{Base64.strict_encode64(photo_result.body)}\">"

      if params[:message][:caption]
        body += "<br>#{params[:message][:caption].text2html}"
      end
      article.content_type = 'text/html'
      article.body         = body
      article.save!
      return article
    end

    # add document
    if params[:message][:document]

      document = params[:message][:document]
      thumb    = params[:message][:document][:thumb]
      body     = '&nbsp;'

      if thumb
        width        = thumb[:width]
        height       = thumb[:height]
        thumb_result = get_file(params, thumb)
        body         = "<img style=\"width:#{width}px;height:#{height}px;\" src=\"data:image/png;base64,#{Base64.strict_encode64(thumb_result.body)}\">"
      end
      if params[:message][:caption]
        body += "<br>#{params[:message][:caption].text2html}"
      end
      document_result      = get_file(params, document)
      article.content_type = 'text/html'
      article.body         = body
      article.save!

      Store.remove(
        object: 'Ticket::Article',
        o_id:   article.id,
      )
      Store.add(
        object:      'Ticket::Article',
        o_id:        article.id,
        data:        document_result.body,
        filename:    document[:file_name],
        preferences: {
          'Mime-Type' => document[:mime_type],
        },
      )
      return article
    end

    # add video
    if params[:message][:video]

      video = params[:message][:video]
      thumb = params[:message][:video][:thumb]
      body = '&nbsp;'

      if thumb
        width        = thumb[:width]
        height       = thumb[:height]
        thumb_result = get_file(params, thumb)
        body         = "<img style=\"width:#{width}px;height:#{height}px;\" src=\"data:image/png;base64,#{Base64.strict_encode64(thumb_result.body)}\">"
      end

      if params[:message][:caption]
        body += "<br>#{params[:message][:caption].text2html}"
      end
      video_result         = get_file(params, video)
      article.content_type = 'text/html'
      article.body         = body
      article.save!

      Store.remove(
        object: 'Ticket::Article',
        o_id:   article.id,
      )

      # get video type
      type = video[:mime_type].gsub(%r{(.+/)}, '')
      Store.add(
        object:      'Ticket::Article',
        o_id:        article.id,
        data:        video_result.body,
        filename:    video[:file_name] || "video-#{video[:file_id]}.#{type}",
        preferences: {
          'Mime-Type' => video[:mime_type],
        },
      )
      return article
    end

    # add voice
    if params[:message][:voice]

      voice = params[:message][:voice]
      body  = '&nbsp;'

      if params[:message][:caption]
        body = "<br>#{params[:message][:caption].text2html}"
      end

      document_result      = get_file(params, voice)
      article.content_type = 'text/html'
      article.body         = body
      article.save!

      Store.remove(
        object: 'Ticket::Article',
        o_id:   article.id,
      )
      Store.add(
        object:      'Ticket::Article',
        o_id:        article.id,
        data:        document_result.body,
        filename:    voice[:file_path] || "audio-#{voice[:file_id]}.ogg",
        preferences: {
          'Mime-Type' => voice[:mime_type],
        },
      )
      return article
    end

    # add sticker
    if params[:message][:sticker]

      sticker = params[:message][:sticker]
      emoji   = sticker[:emoji]
      thumb   = sticker[:thumb]
      body    = '&nbsp;'

      if thumb
        width  = thumb[:width]
        height = thumb[:height]
        thumb_result = get_file(params, thumb)
        body = "<img style=\"width:#{width}px;height:#{height}px;\" src=\"data:image/webp;base64,#{Base64.strict_encode64(thumb_result.body)}\">"
        article.content_type = 'text/html'
      elsif emoji
        article.content_type = 'text/plain'
        body = emoji
      end

      article.body = body
      article.save!

      if sticker[:file_id]

        document_result = get_file(params, sticker)
        Store.remove(
          object: 'Ticket::Article',
          o_id:   article.id,
        )
        Store.add(
          object:      'Ticket::Article',
          o_id:        article.id,
          data:        document_result.body,
          filename:    sticker[:file_name] || "#{sticker[:set_name]}.webp",
          preferences: {
            'Mime-Type' => 'image/webp', # mime type is not given from Telegram API but this is actually WebP
          },
        )
      end
      return article
    end

    # add text
    if params[:message][:text]
      article.content_type = 'text/plain'
      article.body = params[:message][:text]
      article.save!
      return article
    end
    raise Exceptions::UnprocessableEntity, 'invalid telegram message'
  end

  def to_group(params, group_id, channel)
    # begin import
    Rails.logger.debug { 'import message' }

    # map channel_post params to message
    if params[:channel_post]
      return if params[:channel_post][:new_chat_title] # happens when channel title is renamed, we use [:chat][:title] already, safely ignore this.

      # NOTE: used .blank? which is a rails method. empty? does not work on integers (values like date, width, height)  to check.
      # need delete_if to remove any empty hashes, .compact only removes keys with nil values.
      params[:message] = {
        document:   {
          file_name: params.dig(:channel_post, :document, :file_name),
          mime_type: params.dig(:channel_post, :document, :mime_type),
          file_id:   params.dig(:channel_post, :document, :file_id),
          file_size: params.dig(:channel_post, :document, :file_size),
          thumb:     {
            file_id:   params.dig(:channel_post, :document, :thumb, :file_id),
            file_size: params.dig(:channel_post, :document, :thumb, :file_size),
            width:     params.dig(:channel_post, :document, :thumb, :width),
            height:    params.dig(:channel_post, :document, :thumb, :height)
          }.compact
        }.delete_if { |_, v| v.blank? },
        video:      {
          duration:  params.dig(:channel_post, :video, :duration),
          width:     params.dig(:channel_post, :video, :width),
          height:    params.dig(:channel_post, :video, :height),
          mime_type: params.dig(:channel_post, :video, :mime_type),
          file_id:   params.dig(:channel_post, :video, :file_id),
          file_size: params.dig(:channel_post, :video, :file_size),
          thumb:     {
            file_id:   params.dig(:channel_post, :video, :thumb, :file_id),
            file_size: params.dig(:channel_post, :video, :thumb, :file_size),
            width:     params.dig(:channel_post, :video, :thumb, :width),
            height:    params.dig(:channel_post, :video, :thumb, :height)
          }.compact
        }.delete_if { |_, v| v.blank? },
        voice:      {
          duration:  params.dig(:channel_post, :voice, :duration),
          mime_type: params.dig(:channel_post, :voice, :mime_type),
          file_id:   params.dig(:channel_post, :voice, :file_id),
          file_size: params.dig(:channel_post, :voice, :file_size)
        }.compact,
        sticker:    {
          width:     params.dig(:channel_post, :sticker, :width),
          height:    params.dig(:channel_post, :sticker, :height),
          emoji:     params.dig(:channel_post, :sticker, :emoji),
          set_name:  params.dig(:channel_post, :sticker, :set_name),
          file_id:   params.dig(:channel_post, :sticker, :file_id),
          file_path: params.dig(:channel_post, :sticker, :file_path),
          file_size: params.dig(:channel_post, :sticker, :file_size),
          thumb:     {
            file_id:   params.dig(:channel_post, :sticker, :thumb, :file_id),
            file_size: params.dig(:channel_post, :sticker, :thumb, :file_size),
            width:     params.dig(:channel_post, :sticker, :thumb, :width),
            height:    params.dig(:channel_post, :sticker, :thumb, :height),
            file_path: params.dig(:channel_post, :sticker, :thumb, :file_path)
          }.compact
        }.delete_if { |_, v| v.blank? },
        chat:       {
          id:         params.dig(:channel_post, :chat, :id),
          first_name: params.dig(:channel_post, :chat, :title),
          last_name:  'Channel',
          username:   "channel#{params.dig(:channel_post, :chat, :id)}"
        },
        from:       {
          id:         params.dig(:channel_post, :chat, :id),
          first_name: params.dig(:channel_post, :chat, :title),
          last_name:  'Channel',
          username:   "channel#{params.dig(:channel_post, :chat, :id)}"
        },
        caption:    (params.dig(:channel_post, :caption) || {}),
        date:       params.dig(:channel_post, :date),
        message_id: params.dig(:channel_post, :message_id),
        text:       params.dig(:channel_post, :text),
        photo:      (params[:channel_post][:photo].map { |photo| { file_id: photo[:file_id], file_size: photo[:file_size], width: photo[:width], height: photo[:height] } } if params.dig(:channel_post, :photo))
      }.delete_if { |_, v| v.blank? }
      params.delete(:channel_post) # discard unused :channel_post hash
    end

    # checks if the channel post is being edited, and map it when it is
    if params[:edited_channel_post]
      # updates on telegram can only be on messages, no attachments
      params[:edited_message] = {
        chat:       {
          id:         params.dig(:edited_channel_post, :chat, :id),
          first_name: params.dig(:edited_channel_post, :chat, :title),
          last_name:  'Channel',
          username:   "channel#{params.dig(:edited_channel_post, :chat, :id)}"
        },
        from:       {
          id:         params.dig(:edited_channel_post, :chat, :id),
          first_name: params.dig(:edited_channel_post, :chat, :title),
          last_name:  'Channel',
          username:   "channel#{params.dig(:edited_channel_post, :chat, :id)}"
        },
        date:       params.dig(:edited_channel_post, :date),
        edit_date:  params.dig(:edited_channel_post, :edit_date),
        message_id: params.dig(:edited_channel_post, :message_id),
        text:       params.dig(:edited_channel_post, :text)
      }
      params.delete(:edited_channel_post) # discard unused :edited_channel_post hash
    end

    # prevent multiple update
    return if !params[:edited_message] && Ticket::Article.exists?(message_id: Telegram.message_id(params))

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
    if text.present? && text.start_with?('/start')
      message(params[:message][:chat][:id], channel.options[:welcome] || 'You are welcome! Just ask me something!', params[:message][:from][:language_code])
      return

    # find ticket and close it
    elsif text.present? && text.start_with?('/end')
      user = to_user(params)

      # get the last ticket of customer which is not closed yet, and close it
      state_ids        = Ticket::State.where(name: %w[closed merged removed]).pluck(:id)
      possible_tickets = Ticket.where(customer_id: user.id).where.not(state_id: state_ids).order(:updated_at)
      ticket           = possible_tickets.find_each.find { |possible_ticket| possible_ticket.preferences[:channel_id] == channel.id }

      return if !ticket

      ticket.state = Ticket::State.find_by(name: 'closed')
      ticket.save!

      return if !channel.options[:goodbye]

      message(params[:message][:chat][:id], channel.options[:goodbye], params[:message][:from][:language_code])
      return
    end

    ticket = nil

    # use transaction
    Transaction.execute(reset_user_id: true) do
      user   = to_user(params)
      ticket = to_ticket(params, user, group_id, channel)
      to_article(params, user, ticket, channel)
    end

    ticket
  end

  def from_article(article)

    message = nil
    Rails.logger.debug { "Create telegram personal message from article to '#{article[:to]}'..." }

    message = {}
    # TODO: create telegram message here

    Rails.logger.debug { message.inspect }
    message
  end

  def get_file(params, file)

    # telegram bot files are limited up to 20MB
    # https://core.telegram.org/bots/api#getfile
    if !validate_file_size(file)
      message_text = 'Telegram file is to big. (Maximum 20mb)'
      message(params[:message][:chat][:id], "Sorry, we could not handle your message. #{message_text}", params[:message][:from][:language_code])
      raise Exceptions::UnprocessableEntity, message_text
    end

    result = download_file(file[:file_id])

    if !validate_download(result)
      message_text = 'Unable to get you file from bot.'
      message(params[:message][:chat][:id], "Sorry, we could not handle your message. #{message_text}", params[:message][:from][:language_code])
      raise Exceptions::UnprocessableEntity, message_text
    end

    result
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

  def validate_file_size(file)
    Rails.logger.error 'validate_file_size'
    Rails.logger.error file[:file_size]
    return false if file[:file_size] >= 20.megabytes

    true
  end

  def validate_download(result)
    return false if !result.success? || !result.body

    true
  end

end
