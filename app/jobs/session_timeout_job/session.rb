# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SessionTimeoutJob::Session
  attr_accessor :session, :user

  delegate :destroy, to: :session

  def initialize(session)
    @session = session
    @user    = User.find_by(id: session.data['user_id'])
  end

  def user?
    user.present?
  end

  def active?
    return true if !user?
    return true if timeout < 1
    return true if session.data['ping'] > timeout.seconds.ago
  end

  def frontend_timeout
    return if !user?

    PushMessages.send_to(user.id, { event: 'session_timeout' })
  end

  def timeout
    @timeout ||= begin
      permissions = Permission.where(id: user.permissions_with_child_ids).pluck(:name)

      result = -1
      config.each do |key, value|
        next if key == 'default'
        next if permissions.exclude?(key)
        next if value.to_i < result

        result = value.to_i
      end

      if result < 1
        result = config['default'].to_i
      end

      result
    end
  end

  def config
    Setting.get('session_timeout')
  end
end
