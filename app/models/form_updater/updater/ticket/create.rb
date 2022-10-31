# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Updater::Ticket::Create < FormUpdater::Updater
  include FormUpdater::Concerns::ChecksCoreWorkflow

  core_workflow_screen 'create_middle'

  def object_type
    ::Ticket
  end
end
