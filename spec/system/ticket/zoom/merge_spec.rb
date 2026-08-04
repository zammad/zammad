# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > Merge action', type: :system do
  describe 'ticket merge action' do
    context 'when source ticket is merged to target ticket' do
      let(:group)         { Group.find_by(name: 'Users') }
      let(:customer)      { create(:customer) }
      let(:source_ticket) { create(:ticket, group:, customer:) }
      let(:target_ticket) { create(:ticket, group:, customer:) }
      let(:search_term)   { target_ticket.number }

      before do
        source_ticket && target_ticket

        visit "#ticket/zoom/#{source_ticket.id}"
      end

      shared_examples 'merges to target ticket' do
        it 'merges to target ticket' do
          find('[data-tab="ticket"] .js-actions').click
          click('[data-type="ticket-merge"]')

          in_modal do
            find('input[name="target_ticket_number"]').fill_in with: search_term

            # trigger the paste event to replace the ticket hook, if present
            execute_script('$("input[name=\"target_ticket_number\"]").trigger("paste")')

            expect(page).to have_no_css('.js-pager')

            click('.js-submit')
          end

          await_empty_ajax_queue

          meta_ticket_number = find('.active .ticketZoom-header .ticket-number')
          expect(meta_ticket_number.text).to eq(target_ticket.number)
        end
      end

      context 'when input field is used without ticket hook' do
        include_examples 'merges to target ticket'
      end

      context 'when input field is used with ticket hook' do
        let(:search_term) { Setting.get('ticket_hook') + target_ticket.number }

        include_examples 'merges to target ticket'
      end
    end

    context 'when merging with open taskbar tabs' do
      let(:group)          { Group.find_by(name: 'Users') }
      let(:customer)       { create(:customer) }
      let(:source_ticket)  { create(:ticket, group:, customer:, title: 'Source ticket to be merged') }
      let(:target_ticket)  { create(:ticket, group:, customer:, title: 'Target ticket of the merge') }
      let(:source_article) { create(:ticket_article, ticket: source_ticket, body: 'Body of the merged source article') }

      def merge_into(ticket)
        find('[data-tab="ticket"] .js-actions').click
        click('[data-type="ticket-merge"]')

        in_modal do
          find('input[name="target_ticket_number"]').fill_in with: ticket.number

          expect(page).to have_no_css('.js-pager')

          click('.js-submit')
        end

        await_empty_ajax_queue
      end

      before do
        source_article
      end

      context 'when the target ticket tab is closed' do
        before do
          visit "#ticket/zoom/#{source_ticket.id}"
        end

        it 'replaces the source task and shows the merged article in the target ticket' do
          merge_into(target_ticket)

          expect(find('.active .ticketZoom-header .ticket-number').text).to eq(target_ticket.number)
          expect(page).to have_css('.active .ticket-article', text: source_article.body)

          within '.tasks-navigation' do
            expect(page).to have_text(target_ticket.title)
            expect(page).to have_no_text(source_ticket.title)
          end
        end
      end

      context 'when the target ticket tab is open as well' do
        before do
          visit "#ticket/zoom/#{target_ticket.id}"
          visit "#ticket/zoom/#{source_ticket.id}"
        end

        it 'removes the source task and keeps the target task' do
          merge_into(target_ticket)

          expect(find('.active .ticketZoom-header .ticket-number').text).to eq(target_ticket.number)

          within '.tasks-navigation' do
            expect(page).to have_text(target_ticket.title)
            expect(page).to have_no_text(source_ticket.title)
          end
        end
      end
    end

  end
end
