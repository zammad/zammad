# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue3763DefaultDateDatetimeDiffClear < ActiveRecord::Migration[5.2]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    ObjectManager::Attribute
      .where(data_type: %w[date datetime])
      .each do |attr|
        attr.data_option[:diff] = nil
        attr.save!
      end
  end
end
