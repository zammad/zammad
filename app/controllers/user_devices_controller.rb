# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class UserDevicesController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def index
    devices = UserDevice.where(user_id: current_user.id).reorder(updated_at: :desc, name: :asc)
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
      if session[:user_device_fingerprint] == device.fingerprint && device.updated_at > 30.minutes.ago
        attributes['current'] = true
      end
      devices_full.push attributes
    end
    model_index_render_result(devices_full)
  end

  def destroy
    begin
      Service::User::Device::Delete.new(user: current_user, device: UserDevice.find_by(user_id: current_user.id, id: params[:id])).execute
    rescue Exceptions::UnprocessableEntity
      # noop
    end

    render json: {}, status: :ok
  end

end
