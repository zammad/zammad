# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class MigrateCatalanUserPreference < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # Migrate user preferences from es-ca to ca
    User.where('preferences LIKE ?', "%\nlocale: es-ca\n%").find_each(batch_size: 1000) do |user|
      user.preferences[:locale] = 'ca'
      user.save(validate: false)
    end
  end
end
