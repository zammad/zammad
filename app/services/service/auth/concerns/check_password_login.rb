# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Service::Auth::Concerns::CheckPasswordLogin
  extend ActiveSupport::Concern

  included do
    def password_login?
      return true if Setting.get('user_show_password_login')
      return true if Setting.where('name LIKE ? AND frontend = true', "#{SqlHelper.quote_like('auth_')}%")
        .map { |provider| provider.state_current['value'] }
        .all?(false)

      false
    end
  end
end
