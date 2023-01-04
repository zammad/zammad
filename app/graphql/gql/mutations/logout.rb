# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Logout < BaseMutation
    description 'End the current session'

    field :success, Boolean, null: false, description: 'Was the logout successful?'

    # Don't require an authenticated user, because that is not present in maintenance_mode,
    #   when users still need to be correctly logged out.
    def self.authorize(...)
      true
    end

    def self.requires_csrf_verification?
      false
    end

    def resolve(...)

      context[:controller].reset_session
      context[:current_user] = nil
      context[:controller].request.env['rack.session.options'][:expire_after] = nil

      { success: true }
    end

  end
end
