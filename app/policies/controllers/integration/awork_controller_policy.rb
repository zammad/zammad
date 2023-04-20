class Controllers::Integration::AworkControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! %i[update create linked_tasks projects types_of_work tasks_by_project], to: 'ticket.agent'
  permit! :verify, to: 'admin.integration.awork'
  default_permit!(['agent.integration.awork', 'admin.integration.awork'])
end