# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AI::Agent::Type, :aggregate_failures, current_user_id: 1, type: :model do
  describe '.available_types' do
    it 'returns all available AI agent types' do
      expect(described_class.available_types).to be_an(Array)

      expect(described_class.available_types.map(&:name)).to include(
        'AI::Agent::Type::TicketGroupDispatcher',
        'AI::Agent::Type::TicketCategorizer',
      )
    end
  end

  describe '.available_type_data' do
    it 'returns data for all available AI agent types' do
      type_data = described_class.available_type_data

      expect(type_data).to be_an(Array)
        .and include(**AI::Agent::Type::TicketGroupDispatcher.new.data)
    end
  end
end
