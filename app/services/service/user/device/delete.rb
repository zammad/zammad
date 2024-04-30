# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::User::Device::Delete < Service::Base
  attr_reader :user, :device

  def initialize(user:, device:)
    super()

    raise Exceptions::UnprocessableEntity, __('UserDevice could not be found.') if device.blank?

    @user = user
    @device = device
  end

  def execute
    Session.all.each do |session|
      next if session.data['user_id'] != user.id
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
