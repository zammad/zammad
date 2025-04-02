# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ChannelsAdmin::WhatsappController < ChannelsAdmin::BaseController
  def area
    'WhatsApp::Business'.freeze
  end

  def create
    channel = Service::Channel::Whatsapp::Create
      .new(params: params.permit!)
      .execute

    render json: channel
  rescue => e
    raise Exceptions::UnprocessableEntity, e.message
  end

  def update
    channel = Service::Channel::Whatsapp::Update
      .new(params: params.permit!, channel_id: params[:id])
      .execute

    render json: channel
  rescue => e
    raise Exceptions::UnprocessableEntity, e.message
  end

  def preload
    data = Service::Channel::Whatsapp::Preload
      .new(business_id: params[:business_id], access_token: params[:access_token])
      .execute

    render json: { data: }
  end
end
