# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > AI > Ticket Summary', type: :system do

  context 'with ticket summary service options', authenticated_as: :admin do
    let(:admin) { create(:admin) }

    before { visit '/#ai/ticket_summary' }

    it 'displays the ticket summary service options and can change them' do
      within(:active_content) do
        find('label', text: 'Open Questions').click
        find('label', text: 'Upcoming Events').click
        find('label', text: 'Customer Sentiment').click
      end

      expect(Setting.get('ai_assistance_ticket_summary_config')).to eq({
                                                                         'generate_on'        => 'on_ticket_detail_opening',
                                                                         'open_questions'     => false, # true by default
                                                                         'upcoming_events'    => false, # true by default
                                                                         'customer_sentiment' => false, # true by default
                                                                       })
    end

    it 'displays the ticket summary generation options and can change them' do
      within(:active_content) do
        # default setting
        expect(Setting.get('ai_assistance_ticket_summary_config')).to include(generate_on: 'on_ticket_detail_opening')

        select('On ticket summary sidebar activation', from: 'generate_on')
        click_on('Submit')

        expect(Setting.get('ai_assistance_ticket_summary_config')).to include(generate_on: 'on_ticket_summary_sidebar_activation')
      end
    end

    context 'without provider configured' do
      before do
        unset_ai_provider
        visit '/#ai/ticket_summary'
        page.refresh
      end

      it 'displays a warning when summary is enabled' do
        within(:active_content) do
          click '.js-aiAssistanceTicketSummarySetting'

          expect(page).to have_text('The provider configuration is missing. Please set up the provider before proceeding in AI > Providers.')
        end
      end
    end
  end
end
