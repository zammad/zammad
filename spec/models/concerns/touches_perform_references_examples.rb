# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

    it 'does not touch AI Agent when only the stored id type changes (integer vs string)' do
      # Ids may be stored as integers (e.g. via API/seeds); re-saving via the UI stores a string.
      performable = create(described_class.name.downcase, perform: { 'ai.ai_agent' => { 'ai_agent_id' => ai_agent.id } })

      expect { performable.update!(perform: { 'ai.ai_agent' => { 'ai_agent_id' => [ai_agent.id.to_s] } }) }
        .not_to change { ai_agent.reload.updated_at }
    end

    context 'with multiple referenced AI agents' do
      let(:performable_with_ai_agents) do
        create(described_class.name.downcase, perform: { 'ai.ai_agent' => { 'ai_agent_id' => [ai_agent.id.to_s, other_ai_agent.id.to_s] } })
      end

      it 'touches all referenced AI agents on create' do
        ai_agent
        other_ai_agent

        expect { performable_with_ai_agents }
          .to change { ai_agent.reload.updated_at }
          .and change { other_ai_agent.reload.updated_at }
      end

      it 'touches a removed AI agent when one of multiple is dropped' do
        performable_with_ai_agents

        expect { performable_with_ai_agents.update!(perform: build_performable(ai_agent)) }
          .to change { other_ai_agent.reload.updated_at }
      end
    end
  end
end
