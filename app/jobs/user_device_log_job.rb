# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class UserDeviceLogJob < ApplicationJob
  def perform(http_user_agent, remote_ip, user_id, fingerprint, type)
    UserDevice.add(
      http_user_agent,
      remote_ip,
      user_id,
      fingerprint,
      type,
    )
  end
end
