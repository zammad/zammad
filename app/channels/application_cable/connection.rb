# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    # The session id is deliberately not a connection identifier: 'where' requires a value for
    #   every identifier, and the public session id of an established connection cannot be
    #   looked up anywhere, since only its hashed private id is stored. Keeping current_user as
    #   the only identifier is what allows all connections of a user to be terminated via
    #   'ActionCable.server.remote_connections.where(current_user: user).disconnect'.
    attr_accessor :sid

    # current_user is stored in the context of GraphQL which is persistent
    #   for the scope of a subscription and cannot be changed from within
    #   other subscriptions.
    # Therefore, on login/logout, a new web socket connection must be made to
    #   reflect the changes within GraphQL.
    def connect
      return if session_id.blank?

      self.current_user = find_verified_user
      self.sid          = session_id
    end

    private

    def find_verified_user
      private_id = Rack::Session::SessionId.new(session_id).private_id

      session = ActiveRecord::SessionStore::Session.find_by(session_id: private_id)
      return if !session

      user = User.find_by(id: session.data['user_id'])

      # The prerequisites of the HTTP transport must be applied here as well (see
      #   ApplicationController::Authenticates#authentication_check_prerequesits), otherwise a
      #   session that was retained across a deactivation would stay authorized on this transport.
      return if !user&.active?
      return if Auth::SwitchedSession.revoked?(session.data['switched_from_user_id'])
      return if Auth::MaintenanceMode.blocks?(user, switched_from_user_id: session.data['switched_from_user_id'])

      user
    end

    def session_id
      @session_id ||= cookies[Zammad::Application::Initializer::SessionStore::SESSION_KEY]
    end
  end
end
