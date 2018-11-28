# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class ChannelsSignalController < ApplicationController
  prepend_before_action -> { authentication_check(permission: 'admin.channel_signal') }

  def index
    assets = {}
    channel_ids = []
    Channel.where(area: 'Sigarillo::Account').order(:id).each do |channel|
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
      channel = Sigarillo.create_or_update_channel(params[:api_url], params[:api_token], params)
    rescue => e
      raise Exceptions::UnprocessableEntity, e.message
    end
    render json: channel
  end

  def update
    channel = Channel.find_by(id: params[:id], area: 'Sigarillo::Account')
    begin
      channel = Sigarillo.create_or_update_channel(params[:api_url], params[:api_token], params, channel)
    rescue => e
      raise Exceptions::UnprocessableEntity, e.message
    end
    render json: channel
  end

  def enable
    channel = Channel.find_by(id: params[:id], area: 'Sigarillo::Account')
    channel.active = true
    channel.save!
    render json: {}
  end

  def disable
    channel = Channel.find_by(id: params[:id], area: 'Sigarillo::Account')
    channel.active = false
    channel.save!
    render json: {}
  end

  def destroy
    channel = Channel.find_by(id: params[:id], area: 'Sigarillo::Account')
    channel.destroy
    render json: {}
  end
end
