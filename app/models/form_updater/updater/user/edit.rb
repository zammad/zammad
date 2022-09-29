# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Updater::User::Edit < FormUpdater::Updater
  include FormUpdater::Concerns::ChecksCoreWorkflow

  def object_type
    ::User
  end
end
