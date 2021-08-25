# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::CoreWorkflowsControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! :perform, to: ['ticket.agent', 'ticket.customer']
  default_permit!('admin.core_workflow')
end
