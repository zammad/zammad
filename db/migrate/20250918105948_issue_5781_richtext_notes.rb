# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue5781RichtextNotes < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    migrate_richtext_note_attributes(
      'User',
      'Organization',
      'Group',
    )
  end

  private

  def migrate_richtext_note_attributes(*klasses)
    klasses.each do |klass|
      attribute = ObjectManager::Attribute.find_by(object_lookup_id: ObjectLookup.by_name(klass), name: 'note')
      next if attribute.blank?

      attribute.data_option[:type] = 'richtext'

      attribute.save!
    end
  end
end
