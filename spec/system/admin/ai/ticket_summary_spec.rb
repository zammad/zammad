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

      # Routing is configuration, so it can be prepared while the switch is off.
      it 'still offers the provider routing' do
        within(:active_content) do
          expect(page).to have_css('.js-featureProviderButton', text: 'Provider')
        end
      end
    end

    context 'when routing the feature to a connection' do
      let(:other_connection) { create(:ai_provider_connection, name: 'Other connection') }

      before do
        create(:ai_provider_connection, :default_chat, name: 'Default connection')
        other_connection
        Setting.set('ai_provider', true)

        visit '/#ai/ticket_summary'
      end

      it 'writes the routing row from the provider modal' do
        within(:active_content) do
          click '.js-featureProviderButton'
        end

        in_modal do
          expect(page).to have_select('provider_connection_id', options: ['Default (Default connection)', 'Default connection', 'Other connection'])

          select 'Other connection', from: 'provider_connection_id'
          click_on 'Submit'
        end

        wait.until { AI::FeatureProvider.find_by(identifier: 'ticket_summarize')&.provider_connection_id == other_connection.id }
      end
    end
  end
end
