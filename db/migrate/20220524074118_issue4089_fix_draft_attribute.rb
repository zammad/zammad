# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Issue4089FixDraftAttribute < ActiveRecord::Migration[5.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    ObjectManager::Attribute.find_by(name: 'shared_drafts', object_lookup_id: ObjectLookup.by_name('Group')).update(editable: false)
  end
end
