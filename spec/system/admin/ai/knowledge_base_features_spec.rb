# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > AI > Knowledge Base Assistant', type: :system do
  context 'with knowledge base features', authenticated_as: :admin do
    let(:admin) { create(:admin) }

    before do
      setup_ai_provider
      allow(VectorIndexSyncJob).to receive(:perform_later)

      visit '/#ai/knowledge_base_features'
    end

    it 'allows disabling knowledge base answer generation' do
      within(:active_content) do
        expect(Setting.get('ai_assistance_kb_answer_from_ticket_generation')).to be(true)

        find('.checkbox--service', text: 'Knowledge Base Answer Generation').find('label').click

        await_empty_ajax_queue

        expect(Setting.get('ai_assistance_kb_answer_from_ticket_generation')).to be(false)
      end
    end

    it 'allows enabling the vector database' do
      expect(Setting.get('vectordb_enabled')).to be(false)

      click '.js-vectordbEnabledSetting'

      await_empty_ajax_queue

      expect(Setting.get('vectordb_enabled')).to be(true)
      expect(VectorIndexSyncJob).to have_received(:perform_later).once
    end

    context 'with a provider that cannot generate embeddings' do
      before do
        AI::ProviderConnection.find_by(name: 'default').update!(provider: 'anthropic', config: { token: 'secret-token' })

        refresh
      end

      it 'displays a warning' do
        expect(page).to have_text('The system currently has no default provider for semantic search. Please define a suitable provider before using this feature.')
      end

      it 'refuses to enable the vector database' do
        click '.js-vectordbEnabledSetting'

        await_empty_ajax_queue

        expect(page).to have_text('No AI provider with a valid embedding model is configured.')
        expect(Setting.get('vectordb_enabled')).to be(false)
        expect(page).to have_no_css('.js-vectordbEnabledSetting input:checked')
      end
    end

    it 'allows saving the relevance score threshold' do
      within(:active_content) do
        fill_in 'ai_assistance_kb_answer_suggestions_relevance_score', with: '42'
        click_on 'Submit'
      end

      expect(page).to have_text('Update successful.')
      expect(Setting.get('ai_assistance_kb_answer_suggestions_relevance_score')).to eq(42)
    end

    it 'shows a validation error for an invalid relevance score' do
      within(:active_content) do
        fill_in 'ai_assistance_kb_answer_suggestions_relevance_score', with: ''
        click_on 'Submit'
      end

      expect(page).to have_text('The relevance score must be a number between 0 and 100.')
      expect(Setting.get('ai_assistance_kb_answer_suggestions_relevance_score')).to eq(86)
    end

    context 'without a provider configured' do
      before do
        unset_ai_provider
        refresh
      end

      it 'displays a warning' do
        within('.js-missingProviderAlert') do
          expect(page).to have_text('The provider configuration is disabled. Before proceeding, please set up at least one provider in AI > Providers.')
        end
      end

      it 'refuses to enable the vector database' do
        click '.js-vectordbEnabledSetting'

        await_empty_ajax_queue

        expect(page).to have_text('No AI provider with a valid embedding model is configured.')
        expect(Setting.get('vectordb_enabled')).to be(false)
        expect(page).to have_no_css('.js-vectordbEnabledSetting input:checked')
        expect(VectorIndexSyncJob).not_to have_received(:perform_later)
      end
    end

    context 'with a delegated administrator without provider permission' do
      let(:role)  { create(:role, permission_names: %w[admin.ai_knowledge_base]) }
      let(:admin) { create(:agent, roles: [role]) }

      before do
        AI::ProviderConnection.find_by(name: 'default').update!(default_embedding: false)
        refresh
      end

      it 'does not display the embedding provider warning' do
        expect(page).to have_no_text('The system currently has no default provider for semantic search.')
      end
    end

  end
end
