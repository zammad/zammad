# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > AI > Ticket Summary', type: :system do

  context 'with ticket summary service options', authenticated_as: :admin do
    let(:admin) { create(:admin) }

    before { visit '/#ai/ticket_summary' }

    it 'displays summary selector before summary generation' do
      within(:active_content) do
        expect(page).to have_text(%r{Summary Selector.*Summary Generation}m)
        expect(page).to have_text('Defines which tickets can use the ticket summary sidebar.')
      end
    end

    it 'displays the ticket summary service options and can change them' do
      within(:active_content) do
        find('label', text: 'Open Questions').click
        find('label', text: 'Upcoming Events').click
        find('label', text: 'Customer Sentiment').click
      end

      expect(Setting.get('ai_assistance_ticket_summary_config')).to eq({
                                                                         'generate_on'        => 'on_ticket_detail_opening',
                                                                         'open_questions'     => true, # false by default
                                                                         'upcoming_events'    => true, # false by default
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

    it 'can configure the ticket summary selector' do
      within(:active_content) do
        find('.js-filterElement .js-attributeSelector select')
          .find('option', text: 'Priority')
          .select_option

        find('.js-filterElement .js-value select')
          .find('option', text: '3 high')
          .select_option

        click_on 'Save'

        expect(Setting.get('ai_assistance_ticket_summary_selector'))
          .to eq({
                   'condition' => {
                     'ticket.priority_id' => {
                       'operator' => 'is',
                       'value'    => ['3'],
                     },
                   },
                 })
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

          expect(page).to have_text('The provider configuration is disabled. Before proceeding, please set up at least one provider in AI > Providers.')
        end
      end
    end
  end
end
