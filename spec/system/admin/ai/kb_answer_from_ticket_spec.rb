# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > AI > Knowledge Base Answer Generation', type: :system do

  context 'with knowledge base answer generation setting', authenticated_as: :admin do
    let(:admin) { create(:admin) }

    before { visit '/#ai/kb_answer_from_ticket' }

    it 'can toggle the knowledge base answer generation setting' do
      within(:active_content) do
        expect(Setting.get('ai_assistance_kb_answer_from_ticket_generation')).to be(false)

        click '.js-aiAssistanceKbAnswerFromTicketSetting'

        expect(Setting.get('ai_assistance_kb_answer_from_ticket_generation')).to be(true)
      end
    end

    context 'without provider configured' do
      before do
        unset_ai_provider
        visit '/#ai/kb_answer_from_ticket'
        page.refresh
      end

      it 'displays a warning when the setting is enabled' do
        within(:active_content) do
          click '.js-aiAssistanceKbAnswerFromTicketSetting'

          expect(page).to have_text('The provider configuration is disabled. Please set up the provider before proceeding in AI > Providers.')
        end
      end
    end
  end
end
