# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Updater::Ticket::BulkEdit < FormUpdater::Updater
  include FormUpdater::Concerns::ChecksCoreWorkflow

  core_workflow_screen 'overview_bulk'

  def object_type
    ::Ticket
  end
end
