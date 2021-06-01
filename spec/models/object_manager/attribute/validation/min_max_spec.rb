# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'models/object_manager/attribute/validation/backend_examples'

RSpec.describe ::ObjectManager::Attribute::Validation::MinMax do

  subject do
    described_class.new(
      record:    record,
      attribute: attribute
    )
  end

  let(:record) { build(:user) }
  let(:attribute) { build(:object_manager_attribute_integer) }

  it_behaves_like 'validate backend'

  context 'when validation should not be performed' do

    context 'for blank value' do
      let(:value) { nil }

      it_behaves_like 'a validation without errors'
    end

    context 'for irrelevant attribute data_type' do
      let(:value) { 'some_value' }

      before { attribute.data_type = 'select' }

      it_behaves_like 'a validation without errors'
    end
  end

  context 'when validation should be performed' do

    shared_examples 'data_option validator' do |data_option:, data_option_value:, valid:, invalid:|
      context "for data_option '#{data_option}'" do

        before { attribute.data_option[data_option] = data_option_value }

        context 'when value is the same as data_option' do
          let(:value) { data_option_value }

          it_behaves_like 'a validation without errors'
        end

        context 'when value is valid' do
          let(:value) { valid }

          it_behaves_like 'a validation without errors'
        end

        context 'when value is invalid' do
          let(:value) { invalid }

          it_behaves_like 'a validation with errors'
        end
      end
    end

    it_behaves_like 'data_option validator', data_option: :min, data_option_value: 1, valid: 2, invalid: 0
    it_behaves_like 'data_option validator', data_option: :max, data_option_value: 1, valid: 0, invalid: 2
  end
end
