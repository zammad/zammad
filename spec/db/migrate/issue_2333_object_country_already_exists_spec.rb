# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AddCountryAttributeToUsers, type: :db_migration do
  context 'AddCountryAttributeToUsers migration' do
    it 'preserves the existing country attribute' do
      expect { migrate }
        .not_to change { ObjectManager::Attribute.find_by(object_lookup_id: ObjectLookup.by_name('User'), name: 'country') }
    end

    context 'when country attribute is not present' do
      before { ObjectManager::Attribute.find_by(object_lookup_id: ObjectLookup.by_name('User'), name: 'country').delete }

      it 'adds the country attribute when it is not present' do
        expect { migrate }
          .to change { ObjectManager::Attribute.exists?(object_lookup_id: ObjectLookup.by_name('User'), name: 'country') }
          .from(false).to(true)
      end
    end
  end
end
