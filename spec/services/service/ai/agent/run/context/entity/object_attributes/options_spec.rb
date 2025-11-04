# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Agent::Run::Context::Entity::ObjectAttributes::Options, type: :service do
  let(:options_context) { described_class.new(object_attribute: object_attribute, entity_value: entity_value) }

  describe '.applicable?' do
    context 'when options are present' do
      let(:object_attribute) { build(:object_manager_attribute_select) }

      it 'returns true' do
        expect(described_class.applicable?(object_attribute)).to be true
      end
    end

    context 'when options are not present' do
      let(:object_attribute) { build(:object_manager_attribute_text) }

      it 'returns false' do
        expect(described_class.applicable?(object_attribute)).to be false
      end
    end

    context 'when options are empty hash' do
      let(:object_attribute) { build(:object_manager_attribute_select, data_option_options: {}) }

      it 'returns false' do
        expect(described_class.applicable?(object_attribute)).to be false
      end
    end

    context 'when options are empty array' do
      let(:object_attribute) { build(:object_manager_attribute_tree_select) }

      it 'returns false when options array is empty' do
        object_attribute.data_option[:options] = []
        expect(described_class.applicable?(object_attribute)).to be false
      end
    end
  end

  describe '#prepare' do
    context 'with hash options' do
      let(:object_attribute) do
        build(:object_manager_attribute_select, data_option_options: {
                'incident'        => 'Incident',
                'service_request' => 'Service Request',
                'change_request'  => 'Change Request'
              })
      end

      context 'when entity value exists' do
        let(:entity_value) { 'incident' }

        it 'returns the value and label from options' do
          object_attribute.data_option[:historical_options] = {
            'incident'        => 'Incident',
            'service_request' => 'Service Request',
            'change_request'  => 'Change Request'
          }

          result = options_context.prepare

          expect(result).to eq({
                                 value: 'incident',
                                 label: 'Incident'
                               })
        end
      end
    end

    context 'with array options (tree select)' do
      let(:object_attribute) { build(:object_manager_attribute_tree_select) }

      context 'when entity value exists' do
        let(:entity_value) { 'Incident::Hardware::Monitor' }

        it 'returns the value and label' do
          object_attribute.data_option[:historical_options] = {
            'Incident::Hardware::Monitor' => 'Monitor',
            'Incident::Hardware'          => 'Hardware',
            'Incident'                    => 'Incident',
          }

          result = options_context.prepare

          expect(result).to eq({
                                 value: 'Incident::Hardware::Monitor',
                                 label: 'Incident::Hardware::Monitor'
                               })
        end
      end
    end
  end
end
