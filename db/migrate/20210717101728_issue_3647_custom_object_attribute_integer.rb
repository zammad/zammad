# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue3647CustomObjectAttributeInteger < ActiveRecord::Migration[6.0]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    %i[min max].each do |attr|
      ObjectManager::Attribute
        .where(data_type: 'integer', editable: true)
        .each do |attribute|
          next if attribute.data_option[attr] <= 2_147_483_647

          attribute.data_option[attr] = 2_147_483_647
          attribute.save!(validate: false)
        end
    end
  end
end
