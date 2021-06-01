# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ChannelsFacebookController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

  def index
    assets = {}
    ExternalCredential.where(name: 'facebook').each do |external_credential|
      assets = external_credential.assets(assets)
    end
    channel_ids = []
    Channel.where(area: 'Facebook::Account').order(:id).each do |channel|
      assets = channel.assets(assets)
      channel_ids.push channel.id
    end
    render json: {
      assets:       assets,
      channel_ids:  channel_ids,
      callback_url: ExternalCredential.callback_url('facebook'),
    }
  end

  def update
    model_update_render(Channel, params)
  end

  def enable
    channel = Channel.find_by(id: params[:id], area: 'Facebook::Account')
    channel.active = true
    channel.save!
    render json: {}
  end

  def disable
    channel = Channel.find_by(id: params[:id], area: 'Facebook::Account')
    channel.active = false
    channel.save!
    render json: {}
  end

  def destroy
    channel = Channel.find_by(id: params[:id], area: 'Facebook::Account')
    channel.destroy
    render json: {}
  end

end
