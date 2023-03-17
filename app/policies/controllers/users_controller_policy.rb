# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::UsersControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! %i[import_example import_start unlock], to: 'admin.user'
  permit! %i[search history create update], to: ['ticket.agent', 'admin.user']
end
