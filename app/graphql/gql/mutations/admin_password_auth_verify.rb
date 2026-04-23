# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class AdminPasswordAuthVerify < BaseMutation

    description 'Verify admin password authentication'

    argument :token, String, description: 'Token to verify'

    field :login, String, null: true, description: 'Login of the user'

    allow_public_access!

    def resolve(token:)
      user = Service::Auth::VerifyAdminToken.execute(token: token)

      { login: user.login }
    end
  end
end
