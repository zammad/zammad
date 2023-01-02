# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
