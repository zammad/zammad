# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::SessionsControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! %i[list delete], to: 'admin.session'

  def switch_to_user?
    SessionsPolicy.new(user, Sessions).impersonate?
  end
end
