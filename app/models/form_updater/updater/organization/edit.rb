# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Updater::Organization::Edit < FormUpdater::Updater
  include FormUpdater::Concerns::ChecksCoreWorkflow

  core_workflow_screen 'edit'

  def self.required_permissions
    %w[ticket.agent admin.organization]
  end

  def self.object_pundit_method
    :update?
  end

  def object_type
    ::Organization
  end
end
