# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/pagination_examples'

RSpec.describe 'Manage > AI > Text Tool', type: :system do
  context 'when ajax pagination' do
    include_examples 'pagination', model: :ai_text_tool, klass: AI::TextTool, path: 'ai/text_tools'
  end

  context 'with text tools', authenticated_as: :admin do
    let(:admin)        { create(:admin) }
    let(:ai_text_tool) { create(:ai_text_tool) }

    context 'with provider configured' do
      before do
        allow(AI::Provider::ZammadAI).to receive(:ping!).and_return(true)

        setup_ai_provider
        Setting.set('ai_assistance_text_tools', true)
      end

      it 'allows disabling writing assistant' do
        visit '/#ai/text_tools'

        find('.js-toggle-switch-ai_text_tools').click

        await_empty_ajax_queue

        expect(Setting.get('ai_assistance_text_tools')).to be_falsey
      end
    end

    context 'with a delegated administrator without provider permission' do
      let(:role)            { create(:role, permission_names: %w[admin.ai_assistance_text_tools]) }
      let(:delegated_admin) { create(:agent, roles: [role]) }

      before do
        setup_ai_provider
        Setting.set('ai_assistance_text_tools', true)
      end

      it 'hides the connection selector', authenticated_as: :delegated_admin do
        visit '/#ai/text_tools'

        within :active_content do
          expect(page).to have_css('.js-toggle-switch-ai_text_tools')
          expect(page).to have_no_css('.js-featureConnectionSelector')
        end
      end
    end

    context 'without provider configured' do
      before do
        unset_ai_provider
        Setting.set('ai_assistance_text_tools', true)
      end

      it 'displays a warning when writing assistant is enabled' do
        visit '/#ai/text_tools'

        within('.js-missingProviderAlert') do
          expect(page).to have_text('The provider configuration is disabled. Before proceeding, please set up at least one provider in AI > Providers.')
        end
      end
    end
  end
end
