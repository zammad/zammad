# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'TouchesPerformReferences' do |_options = {}|
  context 'when referencing AI Agent' do
    let(:ai_agent)       { create(:ai_agent) }
    let(:other_ai_agent) { create(:ai_agent) }
    let(:performable_with_ai_agent) do
      create(described_class.name.downcase, perform: build_performable(ai_agent))
    end

    def build_performable(agent)
      { 'ai.ai_agent' => { 'ai_agent_id' => agent.id } }
    end

    it 'touches AI agents on create' do
      ai_agent

      expect { performable_with_ai_agent }
        .to change { ai_agent.reload.updated_at }
    end

    it 'touches AI agents on removal' do
      performable_with_ai_agent

      expect { performable_with_ai_agent.update!(perform: { test: true }) }
        .to change { ai_agent.reload.updated_at }
    end

    it 'touches both old and new AI agents on change' do
      performable_with_ai_agent

      other_ai_agent

      expect { performable_with_ai_agent.update!(perform: build_performable(other_ai_agent)) }
        .to change { ai_agent.reload.updated_at }
        .and change { other_ai_agent.reload.updated_at }
    end

    it 'touches AI Agent on object renaming' do
      performable_with_ai_agent

      expect { performable_with_ai_agent.update!(name: 'New Name') }
        .to change { ai_agent.reload.updated_at }
    end

    it 'touches AI Agent on object deletion' do
      performable_with_ai_agent

      expect { performable_with_ai_agent.destroy }
        .to change { ai_agent.reload.updated_at }
    end

    it 'does not touch AI Agent if unrelated object field was changed' do
      performable_with_ai_agent

      expect { performable_with_ai_agent.update!(note: 'New Name') }
        .not_to change { ai_agent.reload.updated_at }
    end

    it 'does not touch AI Agent if unrelated part of perform was changed' do
      performable_with_ai_agent

      performable_with_ai_agent.perform['test'] = true

      expect { performable_with_ai_agent.save! }
        .not_to change { ai_agent.reload.updated_at }
    end
  end
end
