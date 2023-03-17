# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Gql::Context::CurrentUserAware < GraphQL::Query::Context # rubocop:disable GraphQL/ObjectDescription

  # Use this method to fetch the current user when it must be present - it throws an exception otherwise,
  #   making sure unauthenticated requests are handled properly.
  def current_user
    self[:current_user] || raise(Exceptions::NotAuthorized, __('Authentication required'))
  end

  # If the current_user may be absent, use this method.
  def current_user?
    self[:current_user]
  end
end
