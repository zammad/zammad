# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4505InconsistentScreenViewActiveAttribute < ActiveRecord::Migration[6.1]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    object = ObjectManager::Attribute.get(
      name:   'active',
      object: 'Organization'
    )
    object.screens[:view][:'ticket.agent'][:shown] = false
    object.save!
  end
end
