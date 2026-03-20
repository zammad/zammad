# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ChannelsAdmin::WhatsappController < ChannelsAdmin::BaseController
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
    channel = Service::Channel::Whatsapp::Update
      .new(params: params.permit!, channel_id: params[:id])
      .execute

    render json: mask_sensitive_values(channel.as_json, channel)
  rescue => e
    raise Exceptions::UnprocessableEntity, e.message
  end

  def preload
    access_token = params[:access_token]

    if access_token == SensitiveParamsHelper::SENSITIVE_MASK && params[:channel_id].present?
      channel = Channel.in_area(area).find(params[:channel_id])
      access_token = channel.options['access_token']
    end

    data = Service::Channel::Whatsapp::Preload
      .new(business_id: params[:business_id], access_token: access_token)
      .execute

    render json: { data: }
  end

  private

  def sensitive_attributes(_input, _object)
    Channel::SENSITIVE_FIELDS
  end
end
