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

    render json: mask_channel(channel)
  rescue => e
    raise Exceptions::UnprocessableEntity, e.message
  end

  def update
    channel          = Channel.in_area(area).find(params[:id])
    unmasked_params  = unmask_sensitive_params(params.permit!.to_h, channel.options)

    channel = Service::Channel::Whatsapp::Update
      .new(params: unmasked_params, channel_id: params[:id])
      .execute

    render json: mask_channel(channel)
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

  def mask_channel(channel)
    SensitiveParamsHelper
      .new(Channel::SENSITIVE_FIELDS)
      .mask(channel.as_json)
  end
end
