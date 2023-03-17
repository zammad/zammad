# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module UserInfo
  def self.current_user_id
    Thread.current[:user_id]
  end

  def self.current_user_id=(user_id)
    Thread.current[:user_id] = user_id
    Thread.current[:assets]  = UserInfo::Assets.new(user_id)
  end

  def self.assets
    Thread.current[:assets]
  end

  def self.ensure_current_user_id
    if UserInfo.current_user_id.nil?
      UserInfo.current_user_id = 1
      reset_current_user_id    = true
    end

    yield
  ensure
    UserInfo.current_user_id = nil if reset_current_user_id
  end
end
