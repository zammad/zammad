# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ChannelsTelegramController < ApplicationController
  prepend_before_action :authenticate_and_authorize!, except: [:webhook]
  skip_before_action :verify_csrf_token, only: [:webhook]

  def index
    assets = {}
    channel_ids = []
    Channel.where(area: 'Telegram::Bot').reorder(:id).each do |channel|
      assets = channel.assets(assets)
      channel_ids.push channel.id
    end
    render json: {
      assets:      assets,
      channel_ids: channel_ids
    }
  end

  def add
    begin
      channel = TelegramHelper.create_or_update_channel(params[:api_token], params)
    rescue => e
      raise Exceptions::UnprocessableContent, e.message
    end
    render json: mask_sensitive_values(channel.as_json, channel)
  end

  def update
    channel = Channel.find_by(id: params[:id], area: 'Telegram::Bot')
    begin
      channel = TelegramHelper.create_or_update_channel(params[:api_token], params, channel)
    rescue => e
      raise Exceptions::UnprocessableContent, e.message
    end
    render json: mask_sensitive_values(channel.as_json, channel)
  end

  def enable
    channel = Channel.find_by(id: params[:id], area: 'Telegram::Bot')
    channel.active = true
    channel.save!
    render json: {}
  end

  def disable
    channel = Channel.find_by(id: params[:id], area: 'Telegram::Bot')
    channel.active = false
    channel.save!
    render json: {}
  end

  def destroy
    channel = Channel.find_by(id: params[:id], area: 'Telegram::Bot')
    channel.destroy
    render json: {}
  end

  def webhook
    raise Exceptions::UnprocessableContent, 'bot id is missing' if params['bid'].blank?

    channel = TelegramHelper.bot_by_bot_id(params['bid'])
    raise Exceptions::UnprocessableContent, 'bot not found' if !channel

    if channel.options[:callback_token] != params['callback_token']
      raise Exceptions::UnprocessableContent, 'invalid callback token'
    end

    telegram = TelegramHelper.new(channel.options[:api_token])
    begin
      telegram.to_group(params, channel.group_id, channel)
    rescue Exceptions::UnprocessableContent => e
      Rails.logger.error e.message
    end

    render json: {}, status: :ok
  end

end
