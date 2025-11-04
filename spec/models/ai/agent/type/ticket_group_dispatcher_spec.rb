# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AI::Agent::Type::TicketGroupDispatcher, :aggregate_failures, current_user_id: 1, type: :model do
  describe '.execution_definition' do
    let(:type_enrichment_data) { { 'field_name' => 'ticket_id' } }
    let(:agent_type)           { described_class.new(type_enrichment_data:) }

    it 'transforms definition with replacement data' do
      result = agent_type.execution_definition
      expect(result).to be_a(Hash)
    end
  end

  describe '.execution_action_definition' do
    let(:type_enrichment_data) { { 'field_name' => 'group_name' } }
    let(:agent_type) { described_class.new(type_enrichment_data:) }

    it 'transforms action_definition with replacement data' do
      result = agent_type.execution_action_definition
      expect(result).to be_a(Hash)
    end
  end
end
