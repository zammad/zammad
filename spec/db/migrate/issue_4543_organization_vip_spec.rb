# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue4543OrganizationVip, db_strategy: :reset, type: :db_migration do
  before do
    # Clean-up vip field of schema
    ObjectManager::Attribute.remove(object_lookup_id: ObjectLookup.by_name('Organization'), name: 'vip', force: true)
    ObjectManager::Attribute.migration_execute(false)

    # Create custom vip attribute
    vip_attribute
    ObjectManager::Attribute.migration_execute(false)
  end

  context "when a non-boolean 'vip' attribute already exists" do
    let(:vip_attribute) { create(:object_manager_attribute_select, name: 'vip', object_name: 'Organization') }

    it 'renames the existing attribute properly', :aggregate_failures do
      migrate

      expect(vip_attribute.reload.name).to eq('_vip')
      expect(Organization.attribute_names).to include('_vip', 'vip')
    end
  end

  context "when a boolean 'vip' attribute already exists" do
    let(:vip_attribute) { create(:object_manager_attribute_boolean, name: 'vip', display: 'Custom VIP', object_name: 'Organization') }

    it 'keeps the existing attribute and updates it', :aggregate_failures do
      migrate

      expect(vip_attribute.reload).to have_attributes(name: 'vip', display: 'VIP', position: 1450)
      expect(Organization.attribute_names).to include('vip')
      expect(Organization.attribute_names).not_to include('_vip')
    end
  end
end
