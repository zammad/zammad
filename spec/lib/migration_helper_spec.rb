# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MigrationHelper do
  describe '.rename_custom_object_attribute_reserved', db_strategy: :reset do
    it 'does not rename word because it is not reserved' do
      expect { described_class.rename_custom_object_attribute_reserved('asdf') }.to raise_error("Failed to rename 'asdf' because it is neither a global reserved word nor a reserved word for object Ticket!")
    end

    it 'does not rename word because it was only reserved for one model but renamed for all models' do
      new_reserved_names = ObjectManager::Attribute::RESERVED_NAMES_PER_MODEL
      new_reserved_names['Ticket'] << 'asdf'
      stub_const(
        'ObjectManager::Attribute::RESERVED_NAMES_PER_MODEL',
        new_reserved_names
      )

      expect { described_class.rename_custom_object_attribute_reserved('asdf') }.to raise_error("Failed to rename 'asdf' because it is neither a global reserved word nor a reserved word for object TicketArticle!")
    end

    it 'does rename word successfully in all object manager attributes', :aggregate_failures do
      stub_const(
        'ObjectManager::Attribute::RESERVED_NAMES',
        ObjectManager::Attribute::RESERVED_NAMES.dup << 'asdf'
      )
      create(:object_manager_attribute_text, object_name: 'Ticket', name: 'asdf')
      create(:object_manager_attribute_text, object_name: 'User', name: 'asdf')
      create(:object_manager_attribute_text, object_name: 'Organization', name: 'asdf')
      ObjectManager::Attribute.migration_execute

      expect(described_class.rename_custom_object_attribute_reserved('asdf')).to be(true)
      expect(ObjectManager::Attribute.for_object('Ticket').exists?(name: '_asdf')).to be(true)
      expect(Ticket.column_names.include?('_asdf')).to be(true)
      expect(ObjectManager::Attribute.for_object('User').exists?(name: '_asdf')).to be(true)
      expect(User.column_names.include?('_asdf')).to be(true)
      expect(ObjectManager::Attribute.for_object('Organization').exists?(name: '_asdf')).to be(true)
      expect(Organization.column_names.include?('_asdf')).to be(true)
    end
  end
end
