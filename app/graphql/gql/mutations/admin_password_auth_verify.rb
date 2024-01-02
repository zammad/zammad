# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class AdminPasswordAuthVerify < BaseMutation

    description 'Verify admin password authentication'

    argument :token, String, description: 'Token to verify'

    field :login, String, null: true, description: 'Login of the user'

    def self.authorize(_obj, _ctx)
      true
    end

    def resolve(token:)
      verify = Service::Auth::VerifyAdminToken.new(token: token)
      user = verify.execute

      { login: user.login }
    end
  end
end
