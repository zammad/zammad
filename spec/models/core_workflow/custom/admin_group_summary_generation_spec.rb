# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/core_workflow/base'

RSpec.describe CoreWorkflow::Custom::AdminGroupSummaryGeneration, type: :model do
  include_context 'with core workflow base'

  let(:payload) do
    base_payload.merge(
      'class_name' => 'Group',
    )
  end

  context 'when settings enabled' do
    before do
      allow(AI::Provider::ZammadAI).to receive(:ping!).and_return(true)

      setup_ai_provider
      Setting.set('ai_assistance_ticket_summary', true)
    end

    it 'does show ticket generation field for group' do
      expect(result[:visibility]['summary_generation']).to eq('show')
    end
  end

  context 'when settings disabled' do
    before do
      unset_ai_provider
    end

    it 'does not show ticket generation field for group' do
      expect(result[:visibility]['summary_generation']).to eq('remove')
    end
  end

  context 'when feature flag disabled' do
    before do
      allow(AI::Provider::ZammadAI).to receive(:ping!).and_return(true)

      setup_ai_provider
      Setting.set('ai_assistance_ticket_summary', false)
    end

    it 'hides ticket generation field for group' do
      expect(result[:visibility]['summary_generation']).to eq('remove')
    end
  end
end
