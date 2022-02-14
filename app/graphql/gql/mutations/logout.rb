# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Logout < BaseMutation
    description 'End the current session'

    field :success, Boolean, null: false, description: 'Was the logout successful?'

    def self.requires_csrf_verification?
      false
    end

    # Don't require an authenticated user, because that is not present in maintenance_mode,
    #   when users still need to be correctly logged out.

    def resolve(...)

      context[:controller].reset_session
      context[:controller].request.env['rack.session.options'][:expire_after] = nil

      { success: true }
    end

  end
end
