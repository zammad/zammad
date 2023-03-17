# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class AvatarCreateJob < ApplicationJob
  include HasActiveJobLock

  low_priority

  retry_on StandardError, attempts: 20, wait: lambda { |executions|
    executions * 10.seconds
  }

  def lock_key
    # "AvatarCreateJob/User/12"
    "#{self.class.name}/User/#{arguments[0].id}"
  end

  def perform(user)
    avatar = Avatar.auto_detection(
      object: 'User',
      o_id:   user.id,
      url:    user.email
    )

    # update user link
    return if !avatar

    user.update! image: avatar.store_hash
  end
end
