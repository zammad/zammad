# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class MaintenanceCheckmkWordingsOnSettings < ActiveRecord::Migration[5.2]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.find_by(name: 'check_mk_integration').update!(
      title:       'Checkmk integration',
      description: 'Defines if Checkmk (https://checkmk.com/) is enabled or not.',
    )

    Setting.find_by(name: 'check_mk_token').update!(
      title:       'Checkmk token',
      description: 'Defines the Checkmk token for allowing updates.',
    )

  end
end
