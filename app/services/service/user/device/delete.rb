# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::User::Device::Delete < Service::Base
  requires_current_user!

  attr_reader :device

  def initialize(device:)
    raise Exceptions::UnprocessableContent, __('UserDevice could not be found.') if device.blank?

    @device = device
  end

  def execute
    Session.all.each do |session|
      next if session.data['user_id'] != current_user.id
      next if session.data['user_device_fingerprint'] != device.fingerprint

      begin
        session.destroy!
      rescue
        # noop
      end
    end

    device.destroy!
  end
end
