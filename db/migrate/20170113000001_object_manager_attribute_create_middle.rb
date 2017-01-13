class ObjectManagerAttributeCreateMiddle < ActiveRecord::Migration
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    ObjectManager::Attribute.all.each { |attribute|
      next if attribute.name == 'tags'
      next if !attribute.screens
      next if !attribute.screens['create_bottom']
      attribute.screens['create_middle'] = attribute.screens['create_bottom']
      attribute.screens.delete('create_bottom')
      attribute.save!
    }

    attribute = ObjectManager::Attribute.find_by(name: 'priority_id')
    attribute.data_option['nulloption'] = false
    attribute.save!

    Cache.clear
  end
end
