# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::UsersControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! %i[import_example import_start], to: 'admin.user'
  permit! %i[search history create update], to: ['ticket.agent', 'admin.user']
end
