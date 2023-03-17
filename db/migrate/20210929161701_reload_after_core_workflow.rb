# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class ReloadAfterCoreWorkflow < ActiveRecord::Migration[6.0]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    AppVersion.set(true, 'app_version')
  end
end
