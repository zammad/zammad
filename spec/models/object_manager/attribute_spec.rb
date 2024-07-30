# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ObjectManager::Attribute, type: :model do

  describe 'callbacks' do
    context 'for setting default values on local data options' do
      subject(:attr) { described_class.new }

      context ':null' do
        it 'sets nil values to true' do
          expect { attr.validate }
            .to change { attr.data_option[:null] }.to(true)
        end

        it 'does not overwrite false values' do
          attr.data_option[:null] = false

          expect { attr.validate }
            .not_to change { attr.data_option[:null] }
        end
      end

      context ':maxlength' do
        context 'for data_type: select / tree_select / checkbox' do
          subject(:attr) { described_class.new(data_type: 'select') }

          it 'sets nil values to 255' do
            expect { attr.validate }
              .to change { attr.data_option[:maxlength] }.to(255)
          end
        end
      end

      context ':nulloption' do
        context 'for data_type: select / tree_select / checkbox' do
          subject(:attr) { described_class.new(data_type: 'select') }

          it 'sets nil values to true' do
            expect { attr.validate }
              .to change { attr.data_option[:nulloption] }.to(true)
          end

          it 'does not overwrite false values' do
            attr.data_option[:nulloption] = false

            expect { attr.validate }
              .not_to change { attr.data_option[:nulloption] }
          end
        end
      end
    end
  end

  describe 'check name' do
    it 'rejects ActiveRecord reserved word "attribute"' do
      expect do
        described_class.add attributes_for :object_manager_attribute_text, name: 'attribute'
      end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Name attribute is a reserved word')
    end

    %w[destroy true false integer select drop create alter index table varchar blob date datetime timestamp url icon initials avatar permission validate subscribe unsubscribe translate search _type _doc _id id action].each do |reserved_word|
      it "rejects Zammad reserved word '#{reserved_word}'" do
        expect do
          described_class.add attributes_for :object_manager_attribute_text, name: reserved_word
        end.to raise_error(ActiveRecord::RecordInvalid, %r{is a reserved word})
      end
    end

    %w[someting_id something_ids].each do |reserved_word|
      it "rejects word '#{reserved_word}' which is used for database references" do
        expect do
          described_class.add attributes_for :object_manager_attribute_text, name: reserved_word
        end.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Name can't be used because *_id and *_ids are not allowed")
      end
    end

    %w[title tags number].each do |not_editable_attribute|
      it "rejects '#{not_editable_attribute}' which is used" do
        expect do
          described_class.add attributes_for :object_manager_attribute_text, name: not_editable_attribute
        end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Name attribute is not editable')
      end
    end

    %w[priority state note].each do |existing_attribute|
      it "rejects '#{existing_attribute}' which is used" do
        expect do
          described_class.add attributes_for :object_manager_attribute_text, name: existing_attribute
        end.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Name #{existing_attribute} already exists")
      end
    end

    it 'rejects duplicate attribute name of conflicting types' do
      attribute = attributes_for(:object_manager_attribute_text)
      described_class.add attribute
      attribute[:data_type] = 'boolean'
      expect do
        described_class.add attribute
      end.to raise_error ActiveRecord::RecordInvalid
    end

    it 'accepts duplicate attribute name on the same types (editing an existing attribute)' do
      attribute = attributes_for(:object_manager_attribute_text)
      described_class.add attribute
      expect do
        described_class.add attribute
      end.not_to raise_error
    end

    it 'accepts duplicate attribute name on compatible types (editing the type of an existing attribute)' do
      attribute = attributes_for(:object_manager_attribute_text)
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

  describe 'Class methods:' do
    describe '.pending_migration?', db_strategy: :reset do
      it 'returns false if there are no pending migrations' do
        expect(described_class.pending_migration?).to be false
      end

      it 'returns true if there are pending migrations' do
        create(:object_manager_attribute_text)
        expect(described_class.pending_migration?).to be true
      end

      it 'returns false if migration was executed' do
        create(:object_manager_attribute_text)
        described_class.migration_execute
        expect(described_class.pending_migration?).to be false
      end
    end

    describe '.attribute_to_references_hash_objects' do
      it 'returns classes with conditions' do
        expect(described_class.attribute_to_references_hash_objects).to contain_exactly(Trigger, Overview, Job, Sla, Report::Profile)
      end
    end

    describe '.data_options_hash' do
      context 'when hash' do
        let(:check) do
          {
            'a' => 'A',
            'b' => 'B',
            'c' => 'c',
          }
        end

        it 'does return the options as hash' do
          expect(described_class.data_options_hash(check)).to eq({
                                                                   'a' => 'A',
                                                                   'b' => 'B',
                                                                   'c' => 'c',
                                                                 })
        end
      end

      context 'when array' do
        let(:check) do
          [
            {
              value: 'a',
              name:  'A',
            },
            {
              value: 'b',
              name:  'B',
            },
            {
              value: 'c',
              name:  'c',
            },
          ]
        end

        it 'does return the options as hash' do
          expect(described_class.data_options_hash(check)).to eq({
                                                                   'a' => 'A',
                                                                   'b' => 'B',
                                                                   'c' => 'c',
                                                                 })
        end
      end

      context 'when tree array' do
        let(:check) do
          [
            {
              value: 'a',
              name:  'A',
            },
            {
              value: 'b',
              name:  'B',
            },
            {
              value:    'c',
              name:     'c',
              children: [
                {
                  value: 'c::a',
                  name:  'c sub a',
                },
                {
                  value: 'c::b',
                  name:  'c sub b',
                },
                {
                  value: 'c::c',
                  name:  'c sub c',
                },
              ],
            },
          ]
        end

        it 'does return the options as hash' do
          expect(described_class.data_options_hash(check)).to eq({
                                                                   'a'    => 'A',
                                                                   'b'    => 'B',
                                                                   'c'    => 'c',
                                                                   'c::a' => 'c sub a',
                                                                   'c::b' => 'c sub b',
                                                                   'c::c' => 'c sub c',
                                                                 })
        end
      end
    end
  end

  describe 'Data options validation' do
    it 'calls ObjectManager::Attribute::DataOptionValidator' do
      record = described_class.new

      expect_any_instance_of(described_class::DataOptionValidator).to receive(:validate).with(record)

      record.valid?
    end
  end

  describe 'undefined method `to_hash` on editing select fields in the admin interface after migration to 5.1 #4027', db_strategy: :reset do
    let(:select_field) { create(:object_manager_attribute_select) }

    before do
      described_class.migration_execute
    end

    it 'does save the attribute with sorted options' do
      add = select_field.attributes.deep_symbolize_keys
      add[:data_option_new] = add[:data_option]
      add[:data_option_new][:options] = [
        {
          name:  'a',
          value: 'a',
        },
        {
          name:  'b',
          value: 'b',
        },
        {
          name:  'c',
          value: 'c',
        },
      ]

      described_class.add(add)
      described_class.migration_execute

      expect_result = {
        'key_1' => 'value_1',
        'key_2' => 'value_2',
        'key_3' => 'value_3',
        'a'     => 'a',
        'b'     => 'b',
        'c'     => 'c'
      }
      expect(select_field.reload.data_option[:historical_options]).to eq(expect_result)
    end
  end

  describe '#add' do
    context 'when data is valid' do
      let(:attribute) do
        {
          object:        'Ticket',
          name:          'test1',
          display:       'Test 1',
          data_type:     'input',
          data_option:   {
            maxlength: 200,
            type:      'text',
            null:      false,
          },
          active:        true,
          screens:       {},
          position:      20,
          created_by_id: 1,
          updated_by_id: 1,
          editable:      false,
          to_migrate:    false,
        }
      end

      it 'is successful' do
        expect { described_class.add(attribute) }.to change(described_class, :count)
        expect(described_class.get(object: 'Ticket', name: 'test1')).to have_attributes(attribute)
      end
    end

    context 'when data is invalid' do
      let(:attribute) do
        {
          object:        'Ticket',
          name:          'test2_id',
          display:       'Test 2 with id',
          data_type:     'input',
          data_option:   {
            maxlength: 200,
            type:      'text',
            null:      false,
          },
          active:        true,
          screens:       {},
          position:      20,
          created_by_id: 1,
          updated_by_id: 1,
        }
      end

      it 'raises an error' do
        expect { described_class.add(attribute) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when adding a json field' do
      let(:expected_attributes) do
        {
          data_type: 'autocompletion_ajax_external_data_source',
          active:    true,
        }
      end
      let(:attribute) { create(:object_manager_attribute_autocompletion_ajax_external_data_source) }

      it 'works on postgresql', db_adapter: :postgresql do
        expect { attribute }.to change(described_class, :count)
        expect(attribute).to have_attributes(expected_attributes)
      end

      it 'fails on mysql', db_adapter: :mysql do
        expect { attribute }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Data type can only be created on postgresql databases')
      end
    end
  end

  describe '#get' do
    context 'when attribute exists' do
      before do
        create(:object_manager_attribute_text, name: 'test3')
      end

      it 'returns the attribute' do
        expect(described_class.get(object: 'Ticket', name: 'test3')).to have_attributes(name: 'test3', editable: true)
      end
    end

    context 'when attribute does not exist' do
      it 'returns nil' do
        expect(described_class.get(object: 'Ticket', name: 'test4')).to be_nil
      end
    end
  end

  describe '#remove' do
    context 'when attribute exists' do
      before do
        create(:object_manager_attribute_text, name: 'test3')
      end

      it 'is successful' do
        expect { described_class.remove(object: 'Ticket', name: 'test3') }.to change(described_class, :count)
        expect(described_class.get(object: 'Ticket', name: 'test3')).to be_nil
      end
    end

    context 'when attribute does not exist' do
      it 'raises an error' do
        expect { described_class.remove(object: 'Ticket', name: 'test4') }.to raise_error(RuntimeError)
      end
    end
  end
end
