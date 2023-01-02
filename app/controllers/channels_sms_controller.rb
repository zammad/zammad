# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class ChannelsSmsController < ApplicationController
  prepend_before_action -> { authentication_check && authorize! }, except: [:webhook]
  skip_before_action :verify_csrf_token, only: [:webhook]

  def index
    assets = {}
    render json: {
      account_channel_ids:      channels_data('Sms::Account', assets),
      notification_channel_ids: channels_data('Sms::Notification', assets),
      config:                   channels_config,
      assets:                   assets
    }
  end

  def show
    model_show_render(Channel, params)
  end

  def create
    model_create_render(Channel, channel_params)
  end

  def update
    model_update_render(Channel, channel_params)
  end

  def enable
    channel.update!(active: true)
    render json: channel
  end

  def disable
    channel.update!(active: false)
    render json: channel
  end

  def destroy
    channel.destroy!
    render json: {}
  end

  def test
    raise __("The required parameter 'options.adapter' is missing.") if params[:options][:adapter].blank?

    driver = Channel.driver_class(params[:options][:adapter])
    resp   = driver.new.send(params[:options], test_options)

    render json: { success: resp }
  rescue => e
    render json: { error: e.inspect, error_human: e.message }
  end

  def webhook
    raise Exceptions::UnprocessableEntity, 'token param missing' if params['token'].blank?

    ApplicationHandleInfo.in_context('sms') do
      channel = nil
      Channel.where(active: true, area: 'Sms::Account').each do |local_channel|
        next if local_channel.options[:webhook_token] != params['token']

        channel = local_channel
      end
      if !channel
        render(
          json:   { message: 'channel not found' },
          status: :not_found
        )
        return
      end

      content_type, content = channel.process(params.permit!.to_h)
      send_data content, type: content_type
    end
  end

  private

  def channel
    @channel ||= Channel.lookup(id: params[:id])
  end

  def test_options
    params.permit(:recipient, :message)
  end

  def channel_params
    raise __("The required parameter 'area' is missing.") if params[:area].blank?
    if ['Sms::Notification', 'Sms::Account'].exclude?(params[:area])
      raise "The parameter 'area' has the invalid value '#{params[:area]}'!"
    end
    raise __("The required parameter 'params' is missing.") if params[:options].blank?
    raise __("The required parameter 'options.adapter' is missing.") if params[:options][:adapter].blank?

    params
  end

  def channels_config
    list = []
    Rails.root.glob('app/models/channel/driver/sms/*.rb').each do |path|
      filename = File.basename(path)
      next if !Channel.driver_class("sms/#{filename}").const_defined?(:NAME)

      list.push Channel.driver_class("sms/#{filename}").definition
    end
    list
  end

  def channels_data(area, assets)
    channel_ids = []
    Channel.where(area: area).each do |channel|
      assets = channel.assets(assets)
      channel_ids.push(channel.id)
    end
    channel_ids
  end

end
