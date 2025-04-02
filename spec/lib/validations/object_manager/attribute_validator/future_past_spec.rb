# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/validations/object_manager/attribute_validator/backend_examples'

RSpec.describe Validations::ObjectManager::AttributeValidator::FuturePast do

  subject do
    described_class.new(
      record:    record,
      attribute: attribute
    )
  end

  let(:record)    { build(:user) }
  let(:attribute) { build(:object_manager_attribute_datetime) }

  it_behaves_like 'validate backend'

  shared_examples 'data_option validator' do |data_option:, value:|
    context "with data_option '#{data_option}'" do

      let(:value) { value }

      context 'when data_option is set to true' do

        before { attribute.data_option[data_option] = true }

        it_behaves_like 'a validation without errors'
      end

      context 'when data_option is set to false' do

        before { attribute.data_option[data_option] = false }

        it_behaves_like 'a validation with errors'
      end
    end
  end

  it_behaves_like 'data_option validator', data_option: :future, value: 1.week.from_now
  it_behaves_like 'data_option validator', data_option: :past, value: 1.week.ago

  context 'when validation should not be performed' do

    context 'with blank value' do

      let(:value) { nil }

      it_behaves_like 'a validation without errors'
    end

    context 'with irrelevant attribute data_type' do

      let(:value) { 'some_value' }

      before { attribute.data_type = 'select' }

      it_behaves_like 'a validation without errors'
    end
  end
end
