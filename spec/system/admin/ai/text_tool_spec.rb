# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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

    context 'without provider configured' do
      before do
        unset_ai_provider
        Setting.set('ai_assistance_text_tools', true)
      end

      it 'displays a warning when writing assistant is enabled' do
        visit '/#ai/text_tools'

        within('.js-missingProviderAlert') do
          expect(page).to have_text('The provider configuration is missing. Please set up the provider before proceeding in AI > Providers.')
        end
      end
    end
  end
end
