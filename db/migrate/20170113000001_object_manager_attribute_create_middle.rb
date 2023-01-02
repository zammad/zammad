# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class ObjectManagerAttributeCreateMiddle < ActiveRecord::Migration[4.2]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    ObjectManager::Attribute.all.each do |attribute|
      next if attribute.name == 'tags'
      next if !attribute.screens
      next if !attribute.screens['create_bottom']

      attribute.screens['create_middle'] = attribute.screens['create_bottom']
      attribute.screens.delete('create_bottom')
      attribute.save!
    end

    attribute = ObjectManager::Attribute.find_by(name: 'priority_id')
    attribute.data_option['nulloption'] = false
    attribute.save!

    Rails.cache.clear
  end
end
