# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue4089FixDraftAttribute, type: :db_migration do
  def field
    ObjectManager::Attribute.find_by(name: 'shared_drafts', object_lookup_id: ObjectLookup.by_name('Group'))
  end

  context 'when field does not exist', db_strategy: :reset do
    before do
      field.destroy
      ObjectManager::Attribute.migration_execute
      migrate
    end

    it 'does create the field and set it not editable' do
      expect(field.reload.editable).to be(false)
    end
  end

  context 'when field does exist' do
    before do
      field.update(editable: true)
      migrate
    end

    it 'does set the field to not editable' do
      expect(field.reload.editable).to be(false)
    end
  end
end
