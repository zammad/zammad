# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Gql::Mutations
  class Logout < BaseMutation
    description 'End the current session'

    field :success, Boolean, null: false, description: 'Was the logout successful?'

    def resolve(...)

      context[:controller].reset_session
      context[:controller].request.env['rack.session.options'][:expire_after] = nil

      { success: true }
    end

  end
end
