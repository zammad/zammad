require 'rails_helper'

RSpec.describe AddCountryAttributeToUsers, type: :db_migration do

  context 'AddCountryAttributeToUsers migration' do

    def country_attribute
      ObjectManager::Attribute.find_by(object_lookup_id: ObjectLookup.by_name('User'), name: 'country')
    end

    it 'preserves the existing country attribute' do
      expect { migrate }
        .not_to(change { country_attribute.present? })
    end

    it 'adds the country attribute when it is not present' do
      country_attribute.delete
      expect { migrate }
        .to change { country_attribute.present? }
        .from( false ).to( true )
    end
  end
end
