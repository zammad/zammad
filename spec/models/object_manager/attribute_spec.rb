# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
        described_class.add attributes_for :object_manager_attribute_text, name: 'attribute'
      end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Name attribute is a reserved word! (2)')
    end

    %w[destroy true false integer select drop create alter index table varchar blob date datetime timestamp url icon initials avatar permission validate subscribe unsubscribe translate search _type _doc _id id].each do |reserved_word|
      it "rejects Zammad reserved word '#{reserved_word}'" do
        expect do
          described_class.add attributes_for :object_manager_attribute_text, name: reserved_word
        end.to raise_error(ActiveRecord::RecordInvalid, %r{is a reserved word! \(1\)})
      end
    end

    %w[someting_id something_ids].each do |reserved_word|
      it "rejects word '#{reserved_word}' which is used for database references" do
        expect do
          described_class.add attributes_for :object_manager_attribute_text, name: reserved_word
        end.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Name can't get used because *_id and *_ids are not allowed")
      end
    end

    it 'rejects duplicate attribute name of conflicting types' do
      attribute = attributes_for :object_manager_attribute_text
      described_class.add attribute
      attribute[:data_type] = 'boolean'
      expect do
        described_class.add attribute
      end.to raise_error ActiveRecord::RecordInvalid
    end

    it 'accepts duplicate attribute name on the same types (editing an existing attribute)' do
      attribute = attributes_for :object_manager_attribute_text
      described_class.add attribute
      expect do
        described_class.add attribute
      end.not_to raise_error
    end

    it 'accepts duplicate attribute name on compatible types (editing the type of an existing attribute)' do
      attribute = attributes_for :object_manager_attribute_text
      described_class.add attribute
      attribute[:data_type] = 'select'
      attribute[:data_option_new] = { default: '', options: { 'a' => 'a' } }
      expect do
        described_class.add attribute
      end.not_to raise_error
    end

    it 'accepts valid attribute names' do
      expect do
        described_class.add attributes_for :object_manager_attribute_text
      end.not_to raise_error
    end
  end

  describe 'validate that referenced attributes are not set as inactive' do
    subject(:attr) { create(:object_manager_attribute_text) }

    before do
      allow(described_class)
        .to receive(:attribute_used_by_references?)
        .with(attr.object_lookup.name, attr.name)
        .and_return(is_referenced)

      attr.active = active
    end

    context 'when is used and changing to inactive' do
      let(:active)        { false }
      let(:is_referenced) { true }

      it { is_expected.not_to be_valid }

      it do
        attr.valid?
        expect(attr.errors).not_to be_blank
      end
    end

    context 'when is not used and changing to inactive' do
      let(:active)        { false }
      let(:is_referenced) { false }

      it { is_expected.to be_valid }
    end

    context 'when is used and staying active and chan' do
      let(:active)        { true }
      let(:is_referenced) { true }

      it { is_expected.to be_valid }
    end
  end
end
