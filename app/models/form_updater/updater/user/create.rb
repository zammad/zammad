# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Updater::User::Create < FormUpdater::Updater
  include FormUpdater::Concerns::ChecksCoreWorkflow
  include FormUpdater::Concerns::HasUserPermissions

  core_workflow_screen 'create'

  def object_type
    ::User
  end
end
