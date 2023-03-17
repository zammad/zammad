# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class PermissionUpdates < ActiveRecord::Migration[6.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    permissions_update = [
      {
        name:        'admin.channel_formular',
        preferences: {
          translations: ['Channel - Form']
        },
      },
      {
        name: 'admin.knowledge_base',
        note: 'Create and set up %s',
      },
    ]

    permissions_update.each do |permission|
      fetched_permission = Permission.find_by(name: permission[:name])
      next if !fetched_permission

      if permission[:note]
        # p "Updating note of #{permission[:name]} to #{permission[:note]}"
        fetched_permission.note = permission[:note]
      end

      if permission[:preferences]
        # p "Updating preferences of #{permission[:name]} to #{permission[:preferences]}"
        fetched_permission.preferences = permission[:preferences]
      end

      fetched_permission.save!
    end
  end
end
