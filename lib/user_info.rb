# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module UserInfo
  # the thread-local values the user context consists of. The system context is deliberately not
  # part of it: it marks the unit of work as system work, so it has to survive a reset in the
  # middle of that work - a transaction dispatch must not silently drop it.
  CONTEXT_KEYS = %i[token user_id assets ip switched_from_user_id].freeze

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

  # Resets the user context of the current thread, e.g. before it acts as somebody else. The
  #   system context is not part of it and survives, see CONTEXT_KEYS: this can happen in the
  #   middle of a unit of work. A thread that starts a new unit of work has to drop it too.
  def self.reset
    CONTEXT_KEYS.each { |key| Thread.current[key] = nil }

    # the assets are rebuilt as blank on purpose, that is what current_user_id= would do
    Thread.current[:assets] = UserInfo::Assets.new(nil)
  end

  # never nil: a missing context must be answerable as "unprivileged" rather than force
  # every caller to guard for it, which is how it used to be mistaken for agent level.
  # The user id is written together with the assets, so a missing one implies a blank user.
  def self.assets
    Thread.current[:assets] ||= UserInfo::Assets.new(nil)
  end

  # Grants full asset access to a genuinely userless context, e.g. background work that has to
  #   build assets for somebody else. Without it a blank user context is unprivileged, so a
  #   context that got lost along the way cannot silently unlock agent level data.
  def self.with_system_context
    old_system_context = Thread.current[:system_context]

    Thread.current[:system_context] = true

    yield
  ensure
    Thread.current[:system_context] = old_system_context
  end

  def self.system_context?
    !!Thread.current[:system_context]
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
