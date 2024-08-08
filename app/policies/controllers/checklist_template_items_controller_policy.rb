# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Controllers::ChecklistTemplateItemsControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! %i[index show], to: ['ticket.agent', 'admin.checklist']
  default_permit!(['admin.checklist'])
end
