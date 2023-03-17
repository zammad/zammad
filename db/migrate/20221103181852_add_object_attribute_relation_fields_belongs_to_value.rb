# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class AddObjectAttributeRelationFieldsBelongsToValue < ActiveRecord::Migration[6.1]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    relation_object_attributes_belongs_to_update = [
      {
        object:     'User',
        name:       'organization_ids',
        belongs_to: 'secondary_organizations',
      },
    ]

    relation_object_attributes_belongs_to_update.each do |attribute|
      fetched_attribute = ObjectManager::Attribute.get(name: attribute[:name], object: attribute[:object])

      next if !fetched_attribute

      fetched_attribute.data_option[:belongs_to] = attribute[:belongs_to]

      fetched_attribute.save!
    end
  end
end
