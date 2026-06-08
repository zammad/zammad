# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AI::Agent::Type::TicketCategorizer, :aggregate_failures, current_user_id: 1, type: :model do
  describe '.execution_definition' do
    let(:type_enrichment_data) { { 'category' => 'priority_id' } }
    let(:agent_type)           { described_class.new(type_enrichment_data:) }

    it 'transforms definition with replacement data' do
      result = agent_type.execution_definition

      expect(result).to be_a(Hash)
      expect(result['result_structure']).to include('priority_id')
      expect(result['result_structure']['priority_id']).to eq('string')
    end
  end

  describe '.execution_action_definition' do
    let(:type_enrichment_data) { { 'category' => 'category' } }
    let(:agent_type) { described_class.new(type_enrichment_data:) }

    it 'transforms action_definition with replacement data' do
      result = agent_type.execution_action_definition
      expect(result).to be_a(Hash)
    end
  end

  describe '#fetch_object_attribute_list' do
    let(:agent_type) { described_class.new }
    let(:expected_attributes) do
      [
        { value: 'example_category', name: 'Example Category' },
        { value: 'example_industry', name: 'Example Industry' }
      ]
    end

    before do
      # Create test object manager attributes using built-in factories
      create(:object_manager_attribute_select, name: 'example_category', display: 'Example Category')
      create(:object_manager_attribute_multiselect, name: 'example_industry', display: 'Example Industry')
    end

    it 'returns array of select attributes from Ticket object' do
      result = agent_type.object_attribute_list

      expect(result).to match_array(expected_attributes)
    end

    context 'when attributes with different types are present' do
      before do
        create(:object_manager_attribute_text, name: 'example_text', display: 'Example Text')
        create(:object_manager_attribute_text, name: 'example_organization', display: 'Example Organization', object_name: 'Organization')
      end

      it 'excludes non-select attributes as well as attributes for other objects' do
        result = agent_type.object_attribute_list

        expect(result)
          .to match_array(expected_attributes)
          .and not_include({ value: 'example_text', name: 'Example Text' })
          .and not_include({ value: 'example_organization', name: 'Example Organization' })
      end
    end
  end
end
