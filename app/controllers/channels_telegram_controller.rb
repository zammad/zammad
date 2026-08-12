# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ChannelsTelegramController < ApplicationController
  prepend_before_action :authenticate_and_authorize!, except: [:webhook]
  skip_before_action :verify_csrf_token, only: [:webhook]

  SENSITIVE_FIELDS = %w[api_token].freeze

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
      channel = TelegramHelper.create_or_update_channel(unmasked_api_token(channel), params, channel)
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

  private

  # The bot dialog pre-fills the api token with the masked value it received via assets,
  # so it must be restored instead of being sent to Telegram as the mask.
  def unmasked_api_token(channel)
    unmask_sensitive_params(params.permit!.to_h, channel&.options)['api_token']
  end

  # Masking uses dotted paths (Channel::SENSITIVE_FIELDS) for nested channel JSON responses.
  # Unmasking uses flat keys (SENSITIVE_FIELDS) for params/channel.options hashes.
  def sensitive_attributes(_input, object)
    return Channel::SENSITIVE_FIELDS if object.is_a?(Channel)

    SENSITIVE_FIELDS
  end
end
