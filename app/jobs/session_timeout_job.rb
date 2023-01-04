# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class SessionTimeoutJob < ApplicationJob
  def perform
    sessions.each do |session|
      perform_session(session)
    end
  end

  def perform_session(session)

    # user is optional because it can be deleted already
    if session.user?
      return if session.active?

      # if the user has no active sessions then we
      # make sure to definitely log him out if there
      # is any frontends opened
      if !active_session(session.user)
        session.frontend_timeout
      end
    end

    session.destroy
  end

  def active_session(user)
    @active_session ||= {}
    return @active_session[user.id] if @active_session[user.id].present?

    @active_session[user.id] = sessions.detect { |session| session.active? && session.user? && session.user.id == user.id }
  end

  def sessions
    @sessions ||= ActiveRecord::SessionStore::Session.order(updated_at: :desc).limit(10_000).map { |session| SessionTimeoutJob::Session.new(session) }
  end
end
