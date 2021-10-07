# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Overview', type: :system do
  context 'when logged in as customer', authenticated_as: :customer do
    let!(:customer) { create(:customer) }
    let!(:main_overview) { create(:overview) }
    let!(:other_overview) do
      create(:overview, condition: {
               'ticket.state_id' => {
                 operator: 'is',
                 value:    Ticket::State.where(name: %w[merged]).pluck(:id),
               },
             })
    end

    it 'shows create button when customer has no tickets' do
      visit "ticket/view/#{main_overview.link}"

      within :active_content do
        expect(page).to have_text 'Create your first ticket'
      end
    end

    def authenticate
      Setting.set('customer_ticket_create', false)
      customer
    end

    it 'does not show create button when ticket creation via web is disabled', authenticated_as: :authenticate do
      visit "ticket/view/#{main_overview.link}"

      within :active_content do
        expect(page).to have_text 'You currently don\'t have any tickets.'
      end
    end

    it 'shows overview-specific message if customer has tickets in other overview', performs_jobs: true do
      perform_enqueued_jobs only: TicketUserTicketCounterJob do
        create(:ticket, customer: customer)
      end

      visit "ticket/view/#{other_overview.link}"

      within :active_content do
        expect(page).to have_text 'You have no tickets'
      end
    end

    it 'replaces button with overview-specific message when customer creates a ticket', performs_jobs: true do
      visit "ticket/view/#{other_overview.link}"
      visit 'customer_ticket_new'

      find('[name=title]').fill_in with: 'Title'
      find(:richtext).send_keys 'content'
      find('[name=group_id]').select Group.first.name
      click '.js-submit'

      perform_enqueued_jobs only: TicketUserTicketCounterJob

      visit "ticket/view/#{other_overview.link}"
      within :active_content do
        expect(page).to have_text 'You have no tickets'
      end
    end
  end

  context 'sorting when group by is set' do
    let(:user) { create(:customer) }
    let(:ticket1) { create(:ticket, group: Group.find_by(name: 'Users'), priority_id: 1, customer: user) }
    let(:ticket2) { create(:ticket, group: Group.find_by(name: 'Users'), priority_id: 2, customer: user) }
    let(:ticket3) { create(:ticket, group: Group.find_by(name: 'Users'), priority_id: 3, customer: user) }
    let(:overview) do
      create(:overview, group_by: 'priority', group_direction: group_direction, condition: {
               'ticket.customer_id' => {
                 operator: 'is',
                 value:    user.id
               }
             })
    end

    before do
      ticket1 && ticket2 && ticket3

      visit "ticket/view/#{overview.link}"
    end

    context 'when group direction is default' do
      let(:group_direction) { nil }

      it 'sorts groups 1 > 3' do
        within :active_content do
          expect(find('.table-overview table tbody tr:first-child td:nth-child(1)').text).to match('1 low')
          expect(find('.table-overview table tbody tr:nth-child(5) td:nth-child(1)').text).to match('3 high')
        end
      end

      it 'does not show duplicates when any ticket attribute is updated using bulk update' do
        find("tr[data-id='#{ticket3.id}']").check('bulk', allow_label_click: true)
        select '2 normal', from: 'priority_id'

        click '.js-confirm'
        find('.js-confirm-step textarea').fill_in with: 'test tickets ordering'
        click '.js-submit'

        within :active_content do
          expect(page).to have_css("tr[data-id='#{ticket3.id}']", count: 1)
        end
      end
    end

    context 'when group direction is ASC' do
      let(:group_direction) { 'ASC' }

      it 'sorts groups 1 > 3' do
        within :active_content do
          expect(find('.table-overview table tbody tr:first-child td:nth-child(1)').text).to match('1 low')
          expect(find('.table-overview table tbody tr:nth-child(5) td:nth-child(1)').text).to match('3 high')
        end
      end
    end

    context 'when group direction is DESC' do
      let(:group_direction) { 'DESC' }

      it 'sorts groups 3 > 1' do
        within :active_content do
          expect(find('.table-overview table tbody tr:first-child td:nth-child(1)').text).to match('3 high')
          expect(find('.table-overview table tbody tr:nth-child(5) td:nth-child(1)').text).to match('1 low')
        end
      end
    end
  end
end
