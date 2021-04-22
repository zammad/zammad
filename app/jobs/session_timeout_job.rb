class SessionTimeoutJob < ApplicationJob
  def perform
    sessions.find_each do |session|
      perform_session(session)
    end
  end

  def perform_session(session)
    return if !session.data['user_id']

    user = User.find(session.data['user_id'])
    return if !user

    timeout = get_timeout(user)
    return if session.data['ping'] > Time.zone.now - timeout.seconds

    self.class.destroy_session(user, session)
  end

  def self.destroy_session(user, session)
    PushMessages.send_to(user.id, { event: 'session_timeout' })
    session.destroy
  end

  def sessions
    ActiveRecord::SessionStore::Session.where('updated_at < ?', Time.zone.now - config.values.map(&:to_i).min.seconds)
  end

  def config
    Setting.get('session_timeout')
  end

  def get_timeout(user)
    permissions = Permission.where(id: user.permissions_with_child_ids).pluck(:name)

    timeout = -1
    config.each do |key, value|
      next if key == 'default'
      next if permissions.exclude?(key)
      next if value.to_i < timeout

      timeout = value.to_i
    end

    if timeout == -1
      timeout = config['default'].to_i
    end

    timeout
  end
end
