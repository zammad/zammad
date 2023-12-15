# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Service::Auth::Deprecated::SendAdminToken < Service::Auth::SendAdminToken
  include Service::Auth::Concerns::CheckPasswordLogin

  def initialize(login:)
    super(login:)

    @path = '#login/admin/'
  end
end
