# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe UpdateUserAttributes, type: :db_migration do
  context 'with email attribute' do
    let(:object_manager_attribute) do
      ObjectManager::Attribute
        .find_by(name: 'email', object_lookup_id: ObjectLookup.by_name('User'))
    end

    before do
      object_manager_attribute.screens = {
        signup:          { '-all-' => { 'null' => true } },
        invite_agent:    { '-all-' => { 'null' => true } },
        invite_customer: { '-all-' => { 'null' => true } },
      }
      object_manager_attribute.save!
    end

    it 'makes field required', system_init_done: true do
      expect { migrate }
        .to change { object_manager_attribute.reload.screens }
        .to(
          include(
            signup:          { '-all-' => { 'null' => false } },
            invite_agent:    { '-all-' => { 'null' => false } },
            invite_customer: { '-all-' => { 'null' => false } },
          )
        )
    end
  end

  context 'with role_ids attribute' do
    let(:object_manager_attribute) do
      ObjectManager::Attribute
        .find_by(name: 'role_ids', object_lookup_id: ObjectLookup.by_name('User'))
    end

    before do
      object_manager_attribute.data_option = { other: 'attr' }
      object_manager_attribute.save!
    end

    it 'adds relation data option', system_init_done: true do
      expect { migrate }
        .to change { object_manager_attribute.reload.data_option }
        .to(include(relation: 'Role', other: 'attr'))
    end
  end

  context 'with group_ids attribute' do
    let(:object_manager_attribute) do
      ObjectManager::Attribute
        .find_by(name: 'group_ids', object_lookup_id: ObjectLookup.by_name('User'))
    end

    before do
      object_manager_attribute.screens = { invite_agent: { '-all-' => { 'null' => false } } }
      object_manager_attribute.save!
    end

    it 'makes field required', system_init_done: true do
      expect { migrate }
        .to change { object_manager_attribute.reload.screens }
        .to(
          include(
            invite_agent: { '-all-' => { 'null' => true } },
          )
        )
    end
  end
end
