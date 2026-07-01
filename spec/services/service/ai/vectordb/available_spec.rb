# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::VectorDB::Available do
  subject(:service_result) { described_class.execute }

  context 'when the vector database is disabled' do
    it 'returns false' do
      expect(service_result).to be_falsey
    end
  end

  context 'when the vector database is enabled' do
    before do
      Setting.set('vectordb_enabled', true)
    end

    it 'returns false' do
      expect(service_result).to be_falsey
    end

    context 'when the AI provider is configured' do
      before do
        setup_ai_provider('zammad_ai')
      end

      context 'with ping enabled' do
        it 'returns true' do
          allow_any_instance_of(AI::VectorDB).to receive(:ping?).and_return(:ping)
          expect(service_result).to be_truthy
        end
      end

      context 'with ping disabled' do
        subject(:service_result) { described_class.execute(ping: false) }

        it 'returns true' do
          expect(service_result).to be_truthy
        end
      end
    end
  end
end
