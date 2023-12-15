# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

    private

    def password_login?
      return true if Setting.get('user_show_password_login')
      return true if Setting.where('name LIKE ? AND frontend = true', "#{SqlHelper.quote_like('auth_')}%")
        .map { |provider| provider.state_current['value'] }
        .all?(false)

      false
    end
  end
end
