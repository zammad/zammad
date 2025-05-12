# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Summary', authenticated_as: :authenticate, type: :system do
  let(:agent)                        { create(:agent, groups: [ticket.group]) }
  let(:ticket)                       { create(:ticket) }
  let(:article)                      { create(:ticket_article, ticket:) }
  let(:ai_provider)                  { 'zammad_ai' }
  let(:ai_assistance_ticket_summary) { true }
  let(:checklist)                    { true }
  let(:initial_summary)              { Faker::Lorem.unique.sentence }
  let(:updated_summary)              { Faker::Lorem.unique.sentence }
  let(:initial_cache_key)            { "ticket_summary_#{ticket.id}" }
  let(:updated_cache_key)            { "ticket_summary_#{ticket.id}_2" }

  def authenticate
    Setting.set('ai_provider', ai_provider)
    Setting.set('ai_assistance_ticket_summary', ai_assistance_ticket_summary)
    Setting.set('checklist', checklist)

    article

    agent
  end

  before do
    if defined?(initial_cache_key)
      allow(AI::Service::TicketSummarize)
        .to receive(:cache_key).and_return(initial_cache_key, :noop, updated_cache_key)

      Rails.cache.write(initial_cache_key, { 'summary' => initial_summary, 'suggestions' => (initial_suggestions if defined?(initial_suggestions)) }.compact)
      Rails.cache.write(updated_cache_key, { 'summary' => updated_summary, 'suggestions' => (updated_suggestions if defined?(updated_suggestions)) }.compact)

      allow_any_instance_of(Service::Ticket::AIAssistance::Summarize)
        .to receive(:execute).and_return({ 'summary' => updated_summary, 'suggestions' => (updated_suggestions if defined?(updated_suggestions)) }.compact)
    end

    visit "ticket/zoom/#{ticket.id}"
  end

  describe 'Sidebar' do
    context 'when ai_provider is set' do
      before do
        click '.tabsSidebar-tab[data-tab=summary]'
      end

      it 'displays and updates summary in sidebar', performs_jobs: true do
        within '.sidebar[data-tab="summary"]' do
          expect(page).to have_text 'Conversation Summary'
          expect(page).to have_text initial_summary
        end

        create(:ticket_article, ticket:)

        expect(page).to have_text 'generating the summary for you'

        perform_enqueued_jobs(only: TicketAIAssistanceSummarizeJob)

        within '.sidebar[data-tab="summary"]' do
          expect(page).to have_text updated_summary
        end
      end

      context 'when suggestions are available' do
        let(:initial_suggestions) do
          [
            Faker::Lorem.unique.sentence,
            Faker::Lorem.unique.sentence,
            Faker::Lorem.unique.sentence,
          ]
        end

        it 'shows add buttons' do
          within '.sidebar[data-tab="summary"]' do
            expect(page).to have_text 'Suggested Next Steps'
            expect(find_all('button[aria-label="Add as checklist item"]').length).to eq(3)
            expect(page).to have_button 'Add all to checklist'

            # Create the checklist & add the first item
            find_all('button[aria-label="Add as checklist item"]').first.click
          end

          expect(page).to have_text 'Checklist item successfully added.'

          within '.sidebar[data-tab="summary"]' do
            # Add to an existing checklist
            find_all('button[aria-label="Add as checklist item"]')[1].click
          end

          expect(page).to have_text 'Checklist item successfully added.'

          within '.sidebar[data-tab="summary"]' do
            click_on 'Add all to checklist'
          end

          within '.sidebar[data-tab="checklist"]' do
            expect(page).to have_text 'Checklist'
            expect(find_all('table tbody tr').length).to eq(5)
          end
        end

        context 'with checklist feature disabled' do
          let(:checklist) { false }

          it 'does not show add buttons' do
            within '.sidebar[data-tab="summary"]' do
              expect(page).to have_text 'Suggested Next Steps'
              expect(page).to have_no_button 'Add'
              expect(page).to have_no_button 'Add all to checklist'
            end
          end
        end
      end
    end

    context 'when summary feature is disabled' do
      let(:ai_assistance_ticket_summary) { false }

      it 'does not show sidebar' do
        expect(page).to have_text(ticket.title)
        expect(page).to have_no_css('.tabsSidebar-tab[data-tab=summary]')
      end
    end
  end

  describe 'Banner' do
    context 'when ai_provider is set' do
      it 'displays the summary banner and opens sidebar', performs_jobs: true do
        expect(page).to have_text('Zammad Smart Assist ticket summary has been generated.')

        click_on('See Summary')

        within '.sidebar[data-tab="summary"]' do
          expect(page).to have_text('Summary')
        end

        # Hides the banner after opening the sidebar.
        expect(page).to have_no_text('Zammad Smart Assist ticket summary has been generated.')

        refresh

        # Remembers the seen state of the summary.
        expect(page).to have_no_text('Zammad Smart Assist ticket summary has been generated.')

        perform_enqueued_jobs(only: TicketAIAssistanceSummarizeJob)

        # Restores the banner when the summary is updated.
        expect(page).to have_text('Zammad Smart Assist is preparing summary…')
        expect(page).to have_text('Zammad Smart Assist ticket summary has been generated.')
      end

      it 'allows to hide the summary banner permanently' do
        expect(page).to have_text('Zammad Smart Assist ticket summary has been generated.')

        click_on('Hide ticket summary banner')

        in_modal do
          click '.js-submit'
        end

        expect(page).to have_no_text('has prepared a summary of this ticket.')
        expect(agent.reload.preferences).to include(ticket_summary_banner_hidden: be_truthy)

        refresh

        expect(page).to have_no_text('Zammad Smart Assist ticket summary has been generated.')
      end
    end
  end
end
