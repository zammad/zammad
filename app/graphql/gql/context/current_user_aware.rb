# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Gql::Context::CurrentUserAware < GraphQL::Query::Context

  # Use this method to fetch the current user when it must be present - it throws an exception otherwise,
  #   making sure unauthenticated requests are handled properly.
  def current_user
    current_user? || raise(Exceptions::NotAuthorized, __('Authentication required'))
  end

  # If the current_user may be absent, use this method.
  def current_user?
    self[:current_user] if connection_authorized?
  end

  private

  # Over ActionCable the context carries the channel, and the user stays attached to its connection
  #   for the connection's whole lifetime. A connection that a maintenance mode no longer authorizes
  #   is served as logged out (see ApplicationCable::Connection#still_authorized?), for operations
  #   as well as for subscription updates, which run with the context stored when subscribing.
  def connection_authorized?
    return @connection_authorized if defined?(@connection_authorized)

    connection = self[:channel]&.connection

    @connection_authorized = connection.nil? || connection.still_authorized?
  end
end
