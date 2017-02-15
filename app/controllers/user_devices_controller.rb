# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class UserDevicesController < ApplicationController
  prepend_before_action { authentication_check(permission: 'user_preferences.device') }

  def index
    devices = UserDevice.where(user_id: current_user.id).order('updated_at DESC, name ASC')
    devices_full = []
    devices.each { |device|
      attributes = device.attributes
      if device.location_details['city_name'] && !device.location_details['city_name'].empty?
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
    }
    model_index_render_result(devices_full)
  end

  def destroy

    # find device
    user_device = UserDevice.find_by(user_id: current_user.id, id: params[:id])

    # delete device and session's
    if user_device
      SessionHelper.list.each { |session|
        next if !session.data['user_id']
        next if !session.data['user_device_id']
        next if session.data['user_device_id'] != user_device.id
        SessionHelper.destroy( session.id )
      }
      user_device.destroy
    end
    render json: {}, status: :ok
  end

end
