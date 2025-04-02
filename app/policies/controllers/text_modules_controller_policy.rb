# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::TextModulesControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit! ['admin.text_module']
  permit! %i[index show], to: ['ticket.agent', 'admin.text_module']
  permit! %i[create update destroy import_example import_start], to: 'admin.text_module'
end
