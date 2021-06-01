# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue3195InconsistentGranularAgentPermissionsChat < ActiveRecord::Migration[5.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Permission.create_or_update(
      name:        'chat',
      note:        'Access to %s',
      preferences: {
        translations: ['Chat'],
        disabled:     true,
      },
    )

  end
end
