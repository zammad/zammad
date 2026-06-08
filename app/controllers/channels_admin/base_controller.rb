# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ChannelsAdmin::BaseController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def area
    raise NotImplementedError
  end

  def index
    channels = Service::Channel::Admin::List.execute(area: area)

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
      .execute(area: area, channel_id: params[:id])

    render json: { status: :ok }
  end

  def disable
    Service::Channel::Admin::Disable
      .execute(area: area, channel_id: params[:id])

    render json: { status: :ok }
  end

  def destroy
    Service::Channel::Admin::Destroy
      .execute(area: area, channel_id: params[:id])

    render json: { status: :ok }
  end
end
