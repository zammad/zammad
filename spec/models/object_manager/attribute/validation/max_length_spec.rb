# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/object_manager/attribute/validation/backend_examples'

RSpec.describe ObjectManager::Attribute::Validation::MaxLength do

  subject do
    described_class.new(
      record:    record,
      attribute: attribute
    )
  end

  let(:record) { build(:user) }

  %w[text textarea].each do |suffix|
    let(:attribute) { build("object_manager_attribute_#{suffix}") }

    context "with #{suffix} type" do
      context 'when validation should not be performed' do
        describe 'for blank value' do
          let(:value) { nil }

          it_behaves_like 'a validation without errors'
        end

        describe 'for irrelevant attribute data_type' do
          let(:value) { 'some_value' }

          before { attribute.data_type = 'select' }

          it_behaves_like 'a validation without errors'
        end
      end

      context 'when validation should be performed' do
        describe "for data_option 'maxlength'" do
          before { attribute.data_option[:maxlength] = 10 }

          context 'when value is the same as data_option' do
            let(:value) { 'test valūe' }

            it_behaves_like 'a validation without errors'
          end

          context 'when value is valid' do
            let(:value) { 'test' }

            it_behaves_like 'a validation without errors'
          end

          context 'when value is invalid' do
            let(:value) { 'long text here' }

            it_behaves_like 'a validation with errors'
          end
        end
      end
    end
  end
end
