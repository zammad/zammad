# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/validations/object_manager/attribute_validator/backend_examples'

RSpec.describe Validations::ObjectManager::AttributeValidator::ExternalDataSource, application_handle: 'application_server', db_strategy: :reset do
  subject do
    described_class.new(
      record:    record,
      attribute: attribute,
    )
  end

  let(:record) { build(:ticket) }

  before do
    attribute
    ObjectManager::Attribute.migration_execute
    attribute.reload
  end

  context 'when basic behavior is checked' do
    let(:attribute) { create(:object_manager_attribute_autocompletion_ajax_external_data_source) }

    it_behaves_like 'validate backend'
  end

  context 'with external data source attribute' do
    let(:attribute) { create(:object_manager_attribute_autocompletion_ajax_external_data_source) }

    context 'when value is a valid hash' do
      let(:value) { { 'label' => 'Foo', 'value' => 42 } }

      it_behaves_like 'a validation without errors'
    end

    context 'when value is an empty hash' do
      let(:value) { {} }

      it_behaves_like 'a validation without errors'
    end

    context 'when value is nil' do
      let(:value) { nil }

      it_behaves_like 'a validation without errors'
    end

    context 'when value is a plain string' do
      let(:value) { 'Test' }

      it_behaves_like 'a validation with errors'
    end

    context 'when value is an empty string' do
      let(:value) { '' }

      it_behaves_like 'a validation with errors'
    end

    context 'when value is false' do
      let(:value) { false }

      it_behaves_like 'a validation with errors'
    end

    context 'when value is an empty array' do
      let(:value) { [] }

      it_behaves_like 'a validation with errors'
    end

    context 'when value is a hash with missing keys' do
      let(:value) { { 'label' => 'Foo' } }

      it_behaves_like 'a validation with errors'
    end

    context 'when value is a hash with extra keys' do
      let(:value) { { 'label' => 'Foo', 'value' => 42, 'extra' => 'nope' } }

      it_behaves_like 'a validation with errors'
    end

    context 'when value contains a non-scalar entry' do
      let(:value) { { 'label' => 'Foo', 'value' => { 'nested' => true } } }

      it_behaves_like 'a validation with errors'
    end

    context 'when value contains an array entry' do
      let(:value) { { 'label' => %w[a b], 'value' => 1 } }

      it_behaves_like 'a validation with errors'
    end

    context 'when value contains a symbol entry' do
      let(:value) { { 'label' => :foo, 'value' => 1 } }

      it_behaves_like 'a validation with errors'
    end

    context 'when value contains a boolean entry' do
      let(:value) { { 'label' => 'Foo', 'value' => true } }

      it_behaves_like 'a validation without errors'
    end

    context 'when value contains a float entry' do
      let(:value) { { 'label' => 'Foo', 'value' => 1.5 } }

      it_behaves_like 'a validation without errors'
    end

    context 'when value uses symbol keys' do
      let(:value) { { label: 'Foo', value: 42 } }

      it_behaves_like 'a validation without errors'
    end
  end

  context 'with a different attribute data type' do
    let(:attribute) { create(:object_manager_attribute_text) }
    let(:value)     { 'some_value' }

    it_behaves_like 'a validation without errors'
  end

  context 'when called against the record via update' do
    let(:attribute) { create(:object_manager_attribute_autocompletion_ajax_external_data_source) }
    let(:ticket)    { create(:ticket) }

    it 'rejects a plain string value through the validation chain' do
      expect { ticket.update!(attribute.name => 'Test') }
        .to raise_error(ActiveRecord::RecordInvalid, %r{label.*value}i)
    end

    it 'accepts a properly shaped hash through the validation chain' do
      expect { ticket.update!(attribute.name => { 'label' => 'Foo', 'value' => 1 }) }
        .not_to raise_error
    end
  end
end
