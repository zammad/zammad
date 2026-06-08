# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class InactivateEsCaLocale < ActiveRecord::Migration[8.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    Locale.find_by(locale: 'es-ca')&.update(active: false)

    # Migrate any remaining user preferences from es-ca to ca.
    User.where('preferences LIKE ?', "%\nlocale: es-ca\n%").find_each(batch_size: 1000) do |user|
      user.preferences[:locale] = 'ca'
      user.save(validate: false)
    end
  end
end
