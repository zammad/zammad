# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Issue4530NotesSansImages < ActiveRecord::Migration[6.1]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # This was already migrated Issue4050ImageInNote migration
    # However, new installations were created with a wrong seed value
    # Seed values are now changed
    # Rerunning this migration to set correct values
    # In systems set up in between previous migration and the seed files fix

    [User, Organization, Group].each do |klass|
      note_attr = ObjectManager::Attribute.for_object(klass).find_by(name: :note)

      next if note_attr.blank?
      next if note_attr.data_option[:no_images] == true

      note_attr.data_option[:no_images] = true
      note_attr.save!
    end
  end
end
