class ChannelsSmsController < ApplicationChannelController
  PERMISSION = 'admin.channel_sms'.freeze
  AREA = ['Sms::Notification'.freeze, 'Sms::Account'.freeze].freeze

  prepend_before_action -> { authentication_check(permission: self.class::PERMISSION) }, except: [:webhook]
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

  def test
    raise 'Missing parameter options.adapter' if params[:options][:adapter].blank?

    driver = Channel.driver_class(params[:options][:adapter])
    resp   = driver.new.send(params[:options], test_options)

    render json: { success: resp }
  rescue => e
    render json: { error: e.inspect, error_human: e.message }
  end

  def webhook
    raise Exceptions::UnprocessableEntity, 'token param missing' if params['token'].blank?

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

    conten_type, content = channel.process(params.permit!.to_h)
    send_data content, type: conten_type
  end

  private

  def test_options
    params.permit(:recipient, :message)
  end

  def channel_params
    raise 'Missing area params' if params[:area].blank?
    if !self.class::AREA.include?(params[:area])
      raise "Invalid area '#{params[:area]}'!"
    end
    raise 'Missing options params' if params[:options].blank?
    raise 'Missing options.adapter params' if params[:options][:adapter].blank?

    params
  end

  def channels_config
    list = []
    Dir.glob(Rails.root.join('app', 'models', 'channel', 'driver', 'sms', '*.rb')).each do |path|
      filename = File.basename(path)
      require_dependency "channel/driver/sms/#{filename.sub('.rb', '')}"
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
