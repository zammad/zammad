# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class UserDevicesController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

  def index
    devices = UserDevice.where(user_id: current_user.id).order(updated_at: :desc, name: :asc)
    devices_full = []
    devices.each do |device|
      attributes = device.attributes
      if device.location_details['city_name'].present?
        attributes['location'] += ", #{device.location_details['city_name']}"
      end
      attributes.delete('created_at')
      attributes.delete('device_details')
      attributes.delete('location_details')
      attributes.delete('fingerprint')

      # mark current device to prevent killing own session via user preferences device management
      if session[:user_device_fingerprint] == device.fingerprint && device.updated_at > Time.zone.now - 30.minutes
        attributes['current'] = true
      end
      devices_full.push attributes
    end
    model_index_render_result(devices_full)
  end

  def destroy

    # find device
    user_device = UserDevice.find_by(user_id: current_user.id, id: params[:id])

    # delete device and session's
    if user_device
      SessionHelper.list.each do |session|
        next if !session.data['user_id']
        next if !session.data['user_device_id']
        next if session.data['user_device_id'] != user_device.id

        SessionHelper.destroy( session.id )
      end
      user_device.destroy
    end
    render json: {}, status: :ok
  end

end
