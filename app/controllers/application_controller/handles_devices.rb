# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module ApplicationController::HandlesDevices
  extend ActiveSupport::Concern

  included do
    before_action :user_device_log
  end

  def user_device_log(user = current_user, type = 'session')
    switched_from_user_id = ENV['SWITCHED_FROM_USER_ID'] || session[:switched_from_user_id]
    return true if params[:controller] == 'init' # do no device logging on static initial page
    return true if switched_from_user_id
    return true if current_user_on_behalf # do no device logging for the user on behalf feature
    return true if !user
    return true if !policy(UserDevice).log?
    return true if type == 'SSO'

    time_to_check = true
    user_device_updated_at = session[:user_device_updated_at]
    if ENV['USER_DEVICE_UPDATED_AT']
      user_device_updated_at = Time.zone.parse(ENV['USER_DEVICE_UPDATED_AT'])
    end

    if user_device_updated_at
      # check if entry exists / only if write action
      diff = 10.minutes.ago
      if %w[GET OPTIONS HEAD].include?(request.method)
        diff = 30.minutes.ago
      end

      # only update if needed
      if user_device_updated_at > diff
        time_to_check = false
      end
    end

    # if ip has not changed and ttl in still valid
    remote_ip = ENV['TEST_REMOTE_IP'] || request.remote_ip

    return true if time_to_check == false && session[:user_device_remote_ip] == remote_ip

    session[:user_device_remote_ip] = remote_ip

    # for sessions we need the fingperprint
    if type == 'session'
      if !session[:user_device_updated_at] && !params[:fingerprint] && !session[:user_device_fingerprint]
        raise Exceptions::UnprocessableEntity, __('Need fingerprint param!')
      end

      if params[:fingerprint]
        UserDevice.fingerprint_validation(params[:fingerprint])
        session[:user_device_fingerprint] = params[:fingerprint]
      end
    end

    session[:user_device_updated_at] = Time.zone.now

    # add device if needed
    http_user_agent = ENV['HTTP_USER_AGENT'] || request.env['HTTP_USER_AGENT']
    UserDeviceLogJob.perform_later(
      http_user_agent,
      remote_ip,
      user.id,
      session[:user_device_fingerprint],
      type,
    )
  end
end
