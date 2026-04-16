# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AI::Agent::Type::TicketTextExtractor, :aggregate_failures, current_user_id: 1, type: :model do
  describe '.execution_definition' do
    let(:agent_type)        { described_class.new(type_enrichment_data:) }
    let(:subject_attribute) { agent_type.execution_definition }

    let(:type_enrichment_data) do
      {
        'extracted_text'   => 'order_no',
        'extraction_rules' => 'foo',
        'priority_rules'   => 'bar',
      }
    end

    it 'transforms definition with replacement data' do
      expect(subject_attribute).to be_a(Hash)
        .and include('result_structure' => include('order_no' => 'string'))
    end

    it 'includes extraction and priority rules in the instruction prompt' do
      expect(subject_attribute['instruction']).to include('foo')
        .and include('bar')
    end
  end

  describe '.execution_action_definition' do
    let(:agent_type)        { described_class.new(type_enrichment_data:) }
    let(:subject_attribute) { agent_type.execution_action_definition }

    let(:type_enrichment_data) do
      {
        'extracted_text' => 'order_no',
      }
    end

    it 'transforms action_definition with replacement data' do
      expect(subject_attribute['mapping']).to include(
        'ticket.order_no' => {
          'value' => "\#{ai_agent_result.order_no}",
        },
      )
    end

    it 'includes skip_blank_values: true by default' do
      expect(subject_attribute['skip_blank_values']).to be(true)
    end
  end

  describe '#fetch_object_attribute_list' do
    let(:agent_type)        { described_class.new }
    let(:subject_attribute) { agent_type.object_attribute_list }

    let(:expected_attributes) do
      [
        { value: 'example_order_no', name: 'Example Order No' },
        { value: 'example_order_type', name: 'Example Order Type' }
      ]
    end

    before do
      # Create test object manager attributes using built-in factories.
      create(:object_manager_attribute_text, name: 'example_order_no', display: 'Example Order No')
      create(:object_manager_attribute_select, name: 'example_order_type', display: 'Example Order Type')
    end

    it 'returns array of select attributes from Ticket object' do
      expect(subject_attribute).to match_array(expected_attributes)
    end

    context 'when attributes with different types are present' do
      before do
        create(:object_manager_attribute_multiselect, name: 'example_multiselect', display: 'Example Multiselect')
        create(:object_manager_attribute_boolean, name: 'example_boolean', display: 'Example Boolean', object_name: 'Organization')
      end

      it 'excludes non-select attributes as well as attributes for other objects' do
        expect(subject_attribute)
          .to match_array(expected_attributes)
          .and not_include({ value: 'example_multiselect', name: 'Example Multiselect' })
          .and not_include({ value: 'example_boolean', name: 'Example Boolean' })
      end
    end
  end
end
