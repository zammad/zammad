# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::CoreWorkflowsControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! :perform, to: ['ticket.agent', 'ticket.customer']
  default_permit!('admin.core_workflow')
end
