class ApplicationChannelController < ApplicationController
  # Extending controllers has to define following constants:
  # PERMISSION = "admin.channel_xyz"
  # AREA = "XYZ::Account"

  def index
    render json: channels_data
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

  private

  def channel
    @channel ||= Channel.lookup(id: params[:id])
  end

  def channel_params
    params.permit!.to_s
  end

end
