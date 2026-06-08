# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Updater::User::Invite < FormUpdater::Updater
  include FormUpdater::Concerns::ChecksCoreWorkflow
  include FormUpdater::Concerns::HasUserPermissions

  core_workflow_screen 'invite_agent'

  def self.required_permissions
    %w[admin.wizard]
  end

  def object_type
    ::User
  end

end
