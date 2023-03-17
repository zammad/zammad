# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::SessionsControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! :switch_to_user, to: ['admin.session', 'admin.user']
  permit! %i[list delete], to: 'admin.session'
end
