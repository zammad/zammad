# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Agent::Run::Context::Instruction, type: :service do
  let(:group) { create(:group, name: 'Example Group', note: 'An example group description.') }
  let(:object_attributes_context) do
    {
      'group_id'    => { group.id.to_s => 'Example group for testing purposes' },
      'priority_id' => {}, # this means all priorities
      'type'        => { 'Incident' => 'Incident type tickets' }
    }
  end
  let(:instruction_context) do
    {
      'object_attributes' => object_attributes_context
    }
  end
  let(:instruction) { described_class.new(instruction_context: instruction_context) }

  let(:expected_result) do
    {
      object_attributes: {
        'group_id'    => { items: [{
          value:       group.id,
          label:       'Example Group',
          description: 'Example group for testing purposes'
        }], label: 'Group' },
        'priority_id' => { items: Ticket::Priority.all.map do |priority|
          {
            value: priority.id,
            label: priority.name,
          }
        end, label: 'Priority' },
        'type'        => { items: [ { value: 'Incident', label: 'Incident', description: 'Incident type tickets' } ], label: 'Type' }
      }
    }
  end

  describe '#prepare' do
    context 'when object_attributes_context is blank' do
      let(:instruction_context) do
        {
          object_attributes: {}
        }
      end
      let(:expected_result) { {} }

      it 'returns empty hash' do
        expect(instruction.prepare).to eq(expected_result)
      end
    end

    context 'when object_attributes_context is present' do
      it 'returns prepared instruction context' do
        result = instruction.prepare

        expect(result[:object_attributes]).to eq(expected_result[:object_attributes])
      end
    end

    context 'when placeholder_object_attributes are provided', aggregate_failures: true do
      let(:placeholder_object_attributes) { ['example'] }
      let(:type_enrichment_data) { { 'example' => 'custom_field' } }
      let(:object_attributes_context) do
        {
          'placeholder.example' => { 'key_1' => 'First option description' },
        }
      end
      let(:instruction) do
        described_class.new(
          instruction_context:           instruction_context,
          placeholder_object_attributes: placeholder_object_attributes,
          type_enrichment_data:          type_enrichment_data
        )
      end

      before do
        create(:object_manager_attribute_select, name: 'custom_field', display: 'Custom Field')
      end

      it 'uses placeholder mapping for attribute lookup' do
        result = instruction.prepare

        expect(result[:object_attributes]).to include('custom_field')
        expect(result[:object_attributes]['custom_field'][:label]).to eq('Custom Field')
        expect(result[:object_attributes]['custom_field'][:items]).to include(
          hash_including(
            value:       'key_1',
            label:       'value_1',
            description: 'First option description'
          )
        )
      end
    end
  end
end
