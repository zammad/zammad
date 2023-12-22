# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class AdminPasswordAuthSend < BaseMutation
    include Gql::Concerns::HandlesThrottling

    description 'Sends a email with a token to login via password.'

    argument :login, String, 'Login information that is used to create a token.'

    field :success, Boolean, null: false, description: 'This indicates if sending the token was successful.'

    def self.authorize(...)
      true
    end

    def ready?(login:)
      throttle!(limit: 3, period: 1.minute, by_identifier: login)
    end

    def resolve(login:)
      send = Service::Auth::SendAdminToken.new(login: login)
      succeeded = send.execute

      succeeded ? { success: true } : { success: false }
    end
  end
end
