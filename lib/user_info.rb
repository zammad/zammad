# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module UserInfo
  def self.current_user_id
    Thread.current[:user_id]
  end

  def self.current_user
    User.find_by(id: Thread.current[:user_id])
  end

  def self.current_user_id=(user_id)
    Thread.current[:user_id] = user_id
    Thread.current[:assets]  = UserInfo::Assets.new(user_id)
  end

  def self.current_token
    Thread.current[:token]
  end

  def self.current_token=(token)
    Thread.current[:token] = token
  end

  def self.current_ip
    Thread.current[:ip]
  end

  def self.current_ip=(ip)
    Thread.current[:ip] = ip
  end

  def self.current_switched_from_user_id
    Thread.current[:switched_from_user_id]
  end

  def self.current_switched_from_user_id=(user_id)
    Thread.current[:switched_from_user_id] = user_id
  end

  def self.current_switched_from_user
    return if current_switched_from_user_id.blank?

    User.find_by(id: current_switched_from_user_id)
  end

  # resets the whole user context of the current thread, e.g. when a reused thread starts new work
  def self.reset
    # the token needs to be cleared first, current_user_id= reads it when rebuilding the assets
    self.current_token                 = nil
    self.current_user_id               = nil
    self.current_ip                    = nil
    self.current_switched_from_user_id = nil
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

  def self.with_user_id(user_id)
    old_user_id = current_user_id

    self.current_user_id = user_id

    yield
  ensure
    self.current_user_id = old_user_id
  end
end
