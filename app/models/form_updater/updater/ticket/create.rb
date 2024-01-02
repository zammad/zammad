# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Updater::Ticket::Create < FormUpdater::Updater
  include FormUpdater::Concerns::ChecksCoreWorkflow
  include FormUpdater::Concerns::HasSecurityOptions
  include FormUpdater::Concerns::ProvidesInitialValues

  core_workflow_screen 'create_middle'

  def object_type
    ::Ticket
  end

  def initial_values
    {
      'priority_id' => ::Ticket::Priority.find_by(default_create: true)&.id
    }
  end
end
