# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4012MissingRowsForTextareaFields < ActiveRecord::Migration[6.1]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    ObjectManager::Attribute
      .where(data_type: 'textarea', editable: true)
      .each do |attribute|
        next if attribute.data_option[:rows].is_a?(Integer)

        attribute.data_option[:rows] = 4
        attribute.save!(validate: false)
      end
  end
end
