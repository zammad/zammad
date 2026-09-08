# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Revokes what a deactivated or deleted account still holds:
#
# - Its stored sessions, for a deactivated account. They would otherwise outlive the
#   deactivation, so re-activating the account - a compromised one that is disabled and restored
#   afterwards, for instance - would make every session cookie that existed beforehand valid
#   again, an attacker's included. A session the account switched into another user from is
#   dropped even when the account is deleted, since it is served as the switched-to account.
# - Its established real-time connections. A connection keeps the user it was authenticated as
#   for its whole lifetime (see ApplicationCable::Connection), so dropping the session alone
#   would not stop one that is already open from being served.
module User::TerminatesSessions
  extend ActiveSupport::Concern

  included do
    # Deactivation and deletion must share one callback: ActiveSupport::Callbacks treats two
    #   registrations of the same method name as duplicates and keeps only the last one.
    after_commit :terminate_sessions, if: :access_revoked?
  end

  private

  def access_revoked?
    return true if destroyed?

    # A user can be created as inactive, which counts as a change of 'active' as well, but
    #   cannot hold a session or a connection yet.
    return false if previously_new_record?

    saved_change_to_active?(from: true, to: false)
  end

  def terminate_sessions
    destroy_stored_sessions

    terminate_realtime_connections(self)
  end

  # The sessions table has no user column, and its data is stored as base64 encoded Marshal, so
  #   there is nothing to filter on in SQL: every row has to be deserialized to find the ones
  #   belonging to this user. Acceptable because revoking an account is rare, but it does make
  #   bulk revocation - an LDAP sync, a CSV import, a data privacy task - scale with the number
  #   of sessions.
  def destroy_stored_sessions
    Session.find_each do |session|
      next if session_owner_id(session) != id

      # This account owns the row, so a different user in 'user_id' is the one it switched to.
      switched_to_user_id = session.data['user_id'] if session.data['user_id'] != id

      # A deleted account's own sessions can be left to SessionTimeoutJob, which reaps them
      #   along with everybody else's: they authorize nobody, since every transport looks the
      #   account up and finds it gone. A session it switched into another user from does
      #   authorize somebody, so that one goes here.
      next if destroyed? && switched_to_user_id.blank?

      terminate_switched_realtime_connections(switched_to_user_id)

      session.destroy
    end
  end

  # The account a session belongs to, which is not the one it is served as while an admin is
  #   switched into another user: SessionsController#switch_to_user moves the switched-to user
  #   into 'user_id' and remembers the admin in 'switched_from_user_id'. So a session switched
  #   into this account belongs to that admin and is left alone - destroying it would log them
  #   out of their own session, and switching back works from the session alone - while a session
  #   this account switched out of belongs to this account and is dropped.
  def session_owner_id(session)
    # SessionsController#switch_back_to_user sets the key to nil instead of removing it.
    session.data['switched_from_user_id'].presence || session.data['user_id']
  end

  # A session this account switched out of is served as the switched-to user, so its connections
  #   are identified by that user and the disconnect for this account misses them. They have to
  #   go with the session record, or an open one would keep being served - GraphqlChannel runs
  #   whatever it is asked as the user the connection was authenticated as. The switched-to
  #   account's own connections are dropped along with them, since the two cannot be told apart,
  #   and simply come back.
  def terminate_switched_realtime_connections(switched_to_user_id)
    return if switched_to_user_id.blank?

    switched_to_user = User.find_by(id: switched_to_user_id)
    return if !switched_to_user

    terminate_realtime_connections(switched_to_user)
  end

  # Disconnects all connections of the given user, since current_user is the only connection
  #   identifier. The client reconnects, and with the session gone it comes back unauthenticated.
  def terminate_realtime_connections(user)
    ActionCable.server.remote_connections.where(current_user: user).disconnect
  end
end
