# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/validations/object_manager/attribute_validator/backend_examples'

RSpec.describe Validations::ObjectManager::AttributeValidator::Option, application_handle: 'ai_agent_execution', db_strategy: :reset do
  subject do
    described_class.new(
      record:    record,
      attribute: attribute,
    )
  end

  let(:record) { build(:user) }

  before do
    attribute
    ObjectManager::Attribute.migration_execute
    attribute.reload
  end

  context 'when basic behavior is checked' do
    let(:attribute) { create(:object_manager_attribute_select) }

    it_behaves_like 'validate backend'
  end

  context 'when validation should not be performed' do
    context 'with blank value' do
      let(:attribute) { create(:object_manager_attribute_select) }
      let(:value)     { nil }

      it_behaves_like 'a validation without errors'
    end

    context 'with non-option attribute data_type' do
      let(:attribute) { create(:object_manager_attribute_text) }
      let(:value)     { 'some_value' }

      it_behaves_like 'a validation without errors'
    end
  end

  context 'with select attribute' do
    let(:attribute) { create(:object_manager_attribute_select) }

    context 'when value is valid' do
      let(:value) { 'key_1' }

      it_behaves_like 'a validation without errors'
    end

    context 'when value is invalid' do
      let(:value) { 'invalid_key' }

      it_behaves_like 'a validation with errors'
    end

    context 'when validation is turned off', application_handle: 'application_server' do
      let(:value) { 'invalid_key' }

      it_behaves_like 'a validation without errors'
    end
  end

  context 'with tree_select attribute' do
    let(:attribute) { create(:object_manager_attribute_tree_select) }

    context 'when value is valid' do
      let(:value) { 'Incident' }

      it_behaves_like 'a validation without errors'
    end

    context 'when value is invalid' do
      let(:value) { 'invalid_key' }

      it_behaves_like 'a validation with errors'
    end

    context 'with nested options' do
      context 'when value is valid child' do
        let(:value) { 'Incident::Hardware' }

        it_behaves_like 'a validation without errors'
      end

      context 'when value is valid parent' do
        let(:value) { 'Incident' }

        it_behaves_like 'a validation without errors'
      end

      context 'when value is invalid' do
        let(:value) { 'invalid_key' }

        it_behaves_like 'a validation with errors'
      end
    end

    context 'when validation is turned off', application_handle: 'application_server' do
      let(:value) { 'invalid_key' }

      it_behaves_like 'a validation without errors'
    end
  end

  context 'with multiselect attribute' do
    let(:attribute) { create(:object_manager_attribute_multiselect) }

    context 'when all values are valid' do
      let(:value) { %w[key_1 key_2] }

      it_behaves_like 'a validation without errors'
    end

    context 'when one value is invalid' do
      let(:value) { %w[key_1 invalid_key] }

      it_behaves_like 'a validation with errors'
    end

    context 'when value is not an array' do
      let(:value) { 'key_1' }

      it_behaves_like 'a validation without errors'
    end

    context 'when validation is turned off', application_handle: 'application_server' do
      let(:value) { %w[key_1 invalid_key] }

      it_behaves_like 'a validation without errors'
    end
  end

  context 'with multi_tree_select attribute' do
    let(:attribute) { create(:object_manager_attribute_multi_tree_select) }

    context 'when all values are valid' do
      let(:value) { %w[Incident Incident::Hardware] }

      it_behaves_like 'a validation without errors'
    end

    context 'when one value is invalid' do
      let(:value) { %w[Incident invalid_key] }

      it_behaves_like 'a validation with errors'
    end

    context 'with nested options' do
      context 'when all values are valid' do
        let(:value) { ['Incident::Softwareproblem::SAP::Authentication', 'Incident::Softwareproblem::SAP::Not reachable'] }

        it_behaves_like 'a validation without errors'
      end

      context 'when one value is invalid' do
        let(:value) { ['Incident::Softwareproblem::SAP::Authentication', 'Incident::Softwareproblem::SAP::Invalid'] }

        it_behaves_like 'a validation with errors'
      end
    end

    context 'when validation is turned off', application_handle: 'application_server' do
      let(:value) { %w[Incident invalid_key] }

      it_behaves_like 'a validation without errors'
    end
  end
end
