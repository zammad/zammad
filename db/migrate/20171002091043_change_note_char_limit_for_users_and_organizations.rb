# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ChangeNoteCharLimitForUsersAndOrganizations < ActiveRecord::Migration[5.1]
  def up
    # return if it's a new setup to avoid running the migration
    return if !Setting.exists?(name: 'system_init_done')

    change_column :organizations, :note, :string, limit: 5000
    change_column :users, :note, :string, limit: 5000

    object_id = ObjectLookup.by_name('User')
    attribute = ObjectManager::Attribute.find_by(object_lookup_id: object_id, name: 'note')
    attribute.data_option[:maxlength] = 5000
    attribute.save!

    object_id = ObjectLookup.by_name('Organization')
    attribute = ObjectManager::Attribute.find_by(object_lookup_id: object_id, name: 'note')
    attribute.data_option[:maxlength] = 5000
    attribute.save!
  end

end
