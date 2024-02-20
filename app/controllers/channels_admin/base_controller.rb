# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class ChannelsAdmin::BaseController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def area
    raise NotImplementedError
  end

  def index
    channels = Service::Channel::Admin::List.new(area: area).execute

    assets = {}
    channel_ids = []

    channels.each do |channel|
      assets = channel.assets(assets)
      channel_ids.push channel.id
    end

    render json: {
      assets:      assets,
      channel_ids: channel_ids
    }
  end

  def enable
    Service::Channel::Admin::Enable
      .new(area: area, channel_id: params[:id])
      .execute

    render json: { status: :ok }
  end

  def disable
    Service::Channel::Admin::Disable
      .new(area: area, channel_id: params[:id])
      .execute

    render json: { status: :ok }
  end

  def destroy
    Service::Channel::Admin::Destroy
      .new(area: area, channel_id: params[:id])
      .execute

    render json: { status: :ok }
  end
end
