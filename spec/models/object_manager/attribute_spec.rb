require 'rails_helper'

RSpec.describe ObjectManager::Attribute, type: :model do
  describe 'check name' do
    it 'rejects ActiveRecord reserved word "attribute"' do
      expect do
        ObjectManager::Attribute.add attributes_for :object_manager_attribute_text, name: 'attribute'
      end.to raise_error 'attribute is a reserved word, please choose a different one'
    end

    it 'rejects Zammad reserved word "table"' do
      expect do
        ObjectManager::Attribute.add attributes_for :object_manager_attribute_text, name: 'table'
      end.to raise_error 'table is a reserved word, please choose a different one'
    end

    it 'accepts duplicate attribute name on the same types (editing an existing attribute)' do
      attribute = attributes_for :object_manager_attribute_select
      ObjectManager::Attribute.add attribute
      expect do
        ObjectManager::Attribute.add attribute
      end.to_not raise_error
    end

    it 'accepts valid attribute names' do
      expect do
        ObjectManager::Attribute.add attributes_for :object_manager_attribute_text
      end.to_not raise_error
    end
  end
end
