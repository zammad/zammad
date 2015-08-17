# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class UserDevicesController < ApplicationController
  before_action :authentication_check

  def index
    devices = UserDevice.where(user_id: current_user.id).order('updated_at DESC')
    devices_full = []
    devices.each {|device|
      attributes = device.attributes
      if device.location_details['city']
        attributes['country'] += ", #{device.location_details['city']}"
      end
      attributes.delete('created_at')
      attributes.delete('device_details')
      attributes.delete('location_details')
      devices_full.push attributes
    }
    model_index_render_result(devices_full)
  end

  def destroy
    UserDevice.where(user_id: current_user.id, id: params[:id]).destroy_all
    render json: {}, status: :ok
  end

end
