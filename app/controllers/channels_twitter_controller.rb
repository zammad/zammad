# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class ChannelsTwitterController < ApplicationController
  prepend_before_action { authentication_check(permission: 'admin.channel_twitter') }

  def index
    assets = {}
    ExternalCredential.where(name: 'twitter').each { |external_credential|
      assets = external_credential.assets(assets)
    }
    channel_ids = []
    Channel.where(area: 'Twitter::Account').order(:id).each { |channel|
      assets = channel.assets(assets)
      channel_ids.push channel.id
    }
    render json: {
      assets: assets,
      channel_ids: channel_ids,
      callback_url: ExternalCredential.callback_url('twitter'),
    }
  end

  def update
    model_update_render(Channel, params)
  end

  def enable
    channel = Channel.find_by(id: params[:id], area: 'Twitter::Account')
    channel.active = true
    channel.save!
    render json: {}
  end

  def disable
    channel = Channel.find_by(id: params[:id], area: 'Twitter::Account')
    channel.active = false
    channel.save!
    render json: {}
  end

  def destroy
    channel = Channel.find_by(id: params[:id], area: 'Twitter::Account')
    channel.destroy
    render json: {}
  end

end
