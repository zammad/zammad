# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Service::Auth::Concerns::CheckAdminPasswordAuth
  extend ActiveSupport::Concern

  included do
    def admin_password_auth!
      password_login = Service::CheckFeatureEnabled.new(name: 'user_show_password_login', exception: false).execute
      thirdparty_auth = Setting.where('name LIKE ? AND frontend = true', "#{SqlHelper.quote_like('auth_')}%")
        .map { |provider| provider.state_current['value'] }
        .any?(true)

      raise Service::CheckFeatureEnabled::FeatureDisabledError if password_login || !thirdparty_auth
    end
  end
end
