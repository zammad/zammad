# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

    %w[destroy true false integer select drop create alter index table varchar blob date datetime timestamp url icon initials avatar permission validate subscribe unsubscribe translate search _type _doc _id id action].each do |reserved_word|
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

    %w[title tags number].each do |not_editable_attribute|
      it "rejects '#{not_editable_attribute}' which is used" do
        expect do
          described_class.add attributes_for :object_manager_attribute_text, name: not_editable_attribute
        end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Name Attribute not editable!')
      end
    end

    %w[priority state note].each do |existing_attribute|
      it "rejects '#{existing_attribute}' which is used" do
        expect do
          described_class.add attributes_for :object_manager_attribute_text, name: existing_attribute
        end.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Name #{existing_attribute} already exists!")
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
    describe '.attribute_to_references_hash_objects' do
      it 'returns classes with conditions' do
        expect(described_class.attribute_to_references_hash_objects).to match_array [Trigger, Overview, Job, Sla, Report::Profile ]
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

  describe '#data_option_validations' do
    context 'when maxlength is checked for non-integers' do
      shared_examples 'tests the exception on invalid maxlength values' do |type|
        context "when type '#{type}'" do
          subject(:attr) { described_class.new(data_type: type, data_option: { maxlength: 'brbrbr' }) }

          it 'does throw an exception' do
            expect { attr.save! }.to raise_error(ActiveRecord::RecordInvalid, %r{Data option must have integer for :maxlength})
          end
        end
      end

      include_examples 'tests the exception on invalid maxlength values', 'input'
      include_examples 'tests the exception on invalid maxlength values', 'textarea'
      include_examples 'tests the exception on invalid maxlength values', 'richtext'
    end

    context 'when type is checked' do
      shared_examples 'tests the exception on invalid types' do |type|
        context "when type '#{type}'" do
          subject(:attr) { described_class.new(data_type: type, data_option: { type: 'brbrbr' }) }

          it 'does throw an exception' do
            expect { attr.save! }.to raise_error(ActiveRecord::RecordInvalid, %r{must have one of text/password/tel/fax/email/url for :type})
          end
        end
      end

      include_examples 'tests the exception on invalid types', 'input'
    end

    context 'when min max values are checked' do
      shared_examples 'tests the exception on invalid min max values' do |type|
        context "when type '#{type}'" do
          context 'when no integer for min' do
            subject(:attr) { described_class.new(data_type: type, data_option: { min: 'brbrbr' }) }

            it 'does throw an exception' do
              expect { attr.save! }.to raise_error(ActiveRecord::RecordInvalid, %r{must have integer for :min})
            end
          end

          context 'when no integer for max' do
            subject(:attr) { described_class.new(data_type: type, data_option: { max: 'brbrbr' }) }

            it 'does throw an exception' do
              expect { attr.save! }.to raise_error(ActiveRecord::RecordInvalid, %r{must have integer for :max})
            end
          end

          context 'when high integer for min' do
            subject(:attr) { described_class.new(data_type: type, data_option: { min: 999_999_999_999 }) }

            it 'does throw an exception' do
              expect { attr.save! }.to raise_error(ActiveRecord::RecordInvalid, %r{min must be lower than 2147483648})
            end
          end

          context 'when high integer for max' do
            subject(:attr) { described_class.new(data_type: type, data_option: { max: 999_999_999_999 }) }

            it 'does throw an exception' do
              expect { attr.save! }.to raise_error(ActiveRecord::RecordInvalid, %r{max must be lower than 2147483648})
            end
          end

          context 'when negative high integer for min' do
            subject(:attr) { described_class.new(data_type: type, data_option: { min: -999_999_999_999 }) }

            it 'does throw an exception' do
              expect { attr.save! }.to raise_error(ActiveRecord::RecordInvalid, %r{min must be higher than -2147483648})
            end
          end

          context 'when negative high integer for max' do
            subject(:attr) { described_class.new(data_type: type, data_option: { max: -999_999_999_999 }) }

            it 'does throw an exception' do
              expect { attr.save! }.to raise_error(ActiveRecord::RecordInvalid, %r{max must be higher than -2147483648})
            end
          end

          context 'when min is greater than max' do
            subject(:attr) { described_class.new(data_type: type, data_option: { min: 5, max: 2 }) }

            it 'does throw an exception' do
              expect { attr.save! }.to raise_error(ActiveRecord::RecordInvalid, %r{min must be lower than max})
            end
          end
        end
      end

      include_examples 'tests the exception on invalid min max values', 'integer'
    end

    context 'when default is checked' do
      shared_examples 'tests the exception on missing default' do |type|
        context "when type '#{type}'" do
          subject(:attr) { described_class.new(data_type: type, data_option: {}) }

          it 'does throw an exception' do
            expect { attr.save! }.to raise_error(ActiveRecord::RecordInvalid, %r{must have value for :default})
          end
        end
      end

      include_examples 'tests the exception on missing default', 'select'
      include_examples 'tests the exception on missing default', 'tree_select'
      include_examples 'tests the exception on missing default', 'checkbox'
      include_examples 'tests the exception on missing default', 'boolean'
    end

    context 'when relation is checked' do
      shared_examples 'tests the exception on missing relation' do |type|
        context "when type '#{type}'" do
          subject(:attr) { described_class.new(data_type: type, data_option: {}) }

          it 'does throw an exception' do
            expect { attr.save! }.to raise_error(ActiveRecord::RecordInvalid, %r{must have non-nil value for either :options or :relation})
          end
        end
      end

      include_examples 'tests the exception on missing relation', 'select'
      include_examples 'tests the exception on missing relation', 'tree_select'
      include_examples 'tests the exception on missing relation', 'checkbox'
    end

    context 'when nil options are checked' do
      shared_examples 'tests the exception on missing nil options' do |type|
        context "when type '#{type}'" do
          subject(:attr) { described_class.new(data_type: type, data_option: {}) }

          it 'does throw an exception' do
            expect { attr.save! }.to raise_error(ActiveRecord::RecordInvalid, %r{must have non-nil value for :options})
          end
        end
      end

      include_examples 'tests the exception on missing nil options', 'boolean'
    end

    context 'when future is checked' do
      shared_examples 'tests the exception on missing future' do |type|
        context "when type '#{type}'" do
          subject(:attr) { described_class.new(data_type: type, data_option: {}) }

          it 'does throw an exception' do
            expect { attr.save! }.to raise_error(ActiveRecord::RecordInvalid, %r{must have boolean value for :future})
          end
        end
      end

      include_examples 'tests the exception on missing future', 'datetime'
    end

    context 'when past is checked' do
      shared_examples 'tests the exception on missing past' do |type|
        context "when type '#{type}'" do
          subject(:attr) { described_class.new(data_type: type, data_option: {}) }

          it 'does throw an exception' do
            expect { attr.save! }.to raise_error(ActiveRecord::RecordInvalid, %r{must have boolean value for :past})
          end
        end
      end

      include_examples 'tests the exception on missing past', 'datetime'
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
end
