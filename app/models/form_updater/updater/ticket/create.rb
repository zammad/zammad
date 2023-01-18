# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Updater::Ticket::Create < FormUpdater::Updater
  include FormUpdater::Concerns::ChecksCoreWorkflow
  include FormUpdater::Concerns::HasSecurityOptions

  core_workflow_screen 'create_middle'

  def object_type
    ::Ticket
  end
end
