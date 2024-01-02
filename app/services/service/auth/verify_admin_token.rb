# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::Auth::VerifyAdminToken < Service::Base
  include Service::Auth::Concerns::CheckAdminPasswordAuth

  attr_reader :token

  def initialize(token:)
    super()
    @token = token
  end

  def execute
    admin_password_auth!

    user = ::User.admin_password_auth_via_token(token)
    raise Exceptions::Forbidden, __('The login is not possible.') if !user

    user
  end
end
