require 'rails_helper'

RSpec.describe ObjectManager::Attribute, type: :model do
  describe 'callbacks' do
    context 'for setting default values on local data options' do
      let(:subject) { described_class.new }

      context ':null' do
        it 'sets nil values to true' do
          expect { subject.validate }
            .to change { subject.data_option[:null] }.to(true)
        end

        it 'does not overwrite false values' do
          subject.data_option[:null] = false

          expect { subject.validate }
            .not_to change { subject.data_option[:null] }
        end
      end

      context ':maxlength' do
        context 'for data_type: select / tree_select / checkbox' do
          let(:subject) { described_class.new(data_type: 'select') }

          it 'sets nil values to 255' do
            expect { subject.validate }
              .to change { subject.data_option[:maxlength] }.to(255)
          end
        end
      end

      context ':nulloption' do
        context 'for data_type: select / tree_select / checkbox' do
          let(:subject) { described_class.new(data_type: 'select') }

          it 'sets nil values to true' do
            expect { subject.validate }
              .to change { subject.data_option[:nulloption] }.to(true)
          end

          it 'does not overwrite false values' do
            subject.data_option[:nulloption] = false

            expect { subject.validate }
              .not_to change { subject.data_option[:nulloption] }
          end
        end
      end
    end
  end

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

    it 'rejects duplicate attribute name of conflicting types' do
      attribute = attributes_for :object_manager_attribute_text
      ObjectManager::Attribute.add attribute
      attribute[:data_type] = 'boolean'
      expect do
        ObjectManager::Attribute.add attribute
      end.to raise_error ActiveRecord::RecordInvalid
    end

    it 'accepts duplicate attribute name on the same types (editing an existing attribute)' do
      attribute = attributes_for :object_manager_attribute_text
      ObjectManager::Attribute.add attribute
      expect do
        ObjectManager::Attribute.add attribute
      end.to_not raise_error
    end

    it 'accepts duplicate attribute name on compatible types (editing the type of an existing attribute)' do
      attribute = attributes_for :object_manager_attribute_text
      ObjectManager::Attribute.add attribute
      attribute[:data_type] = 'select'
      attribute[:data_option_new] = { default: '', options: { 'a' => 'a' } }
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
