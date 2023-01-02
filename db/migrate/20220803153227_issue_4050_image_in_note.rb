# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4050ImageInNote < ActiveRecord::Migration[6.1]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    [User, Organization, Group].each do |klass|
      note_attr = ObjectManager::Attribute.for_object(klass).find_by(name: :note)
      note_attr.data_option[:no_images] = true
      note_attr.save!
    end
  end
end
