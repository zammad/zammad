# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ChannelsAdmin::WhatsappController < ChannelsAdmin::BaseController
  SENSITIVE_FIELDS = %w[access_token app_secret].freeze

  def area
    'WhatsApp::Business'.freeze
  end

  def create
    channel = Service::Channel::Whatsapp::Create
      .new(params: params.permit!)
      .execute

    render json: mask_sensitive_values(channel.as_json, channel)
  rescue => e
    raise Exceptions::UnprocessableEntity, e.message
  end

  def update
    channel          = Channel.in_area(area).find(params[:id])
    unmasked_params  = unmask_sensitive_params(params.permit!.to_h, channel.options)

    channel = Service::Channel::Whatsapp::Update
      .new(params: unmasked_params, channel_id: params[:id])
      .execute

    render json: mask_sensitive_values(channel.as_json, channel)
  rescue => e
    raise Exceptions::UnprocessableEntity, e.message
  end

  def preload
    unmasked = unmask_preload_params

    data = Service::Channel::Whatsapp::Preload
      .new(business_id: unmasked[:business_id], access_token: unmasked[:access_token])
      .execute

    render json: { data: }
  end

  private

  def unmask_preload_params
    return params if params[:channel_id].blank?

    channel = Channel.in_area(area).find(params[:channel_id])
    unmask_sensitive_params(params.permit!.to_h, channel.options)
  end

  # Masking uses dotted paths (Channel::SENSITIVE_FIELDS) for nested channel JSON responses.
  # Unmasking uses flat keys (SENSITIVE_FIELDS) for params/channel.options hashes.
  def sensitive_attributes(_input, object)
    return Channel::SENSITIVE_FIELDS if object.is_a?(Channel)

    SENSITIVE_FIELDS
  end
end
