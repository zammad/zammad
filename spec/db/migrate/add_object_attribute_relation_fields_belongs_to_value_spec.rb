# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AddObjectAttributeRelationFieldsBelongsToValue, type: :db_migration do
  context 'when field does not have belongs_to', db_strategy: :reset do
    let(:attribute) { ObjectManager::Attribute.get(name: 'organization_ids', object: 'User') }

    before do
      attribute.data_option.delete(:belongs_to)
      attribute.save!

      ObjectManager::Attribute.migration_execute
    end

    it 'does add belongs_to value inside data option' do
      expect { migrate }.to change { attribute.reload.data_option[:belongs_to] }.from(nil).to('secondary_organizations')
    end
  end
end
