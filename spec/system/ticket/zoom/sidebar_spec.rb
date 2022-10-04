# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > Sidebar', authenticated_as: :user, type: :system do
  let(:ticket) { create(:ticket, customer: user, group: group, state: Ticket::State.find_by(name: 'closed')) }
  let(:user)   { create(:customer, organization: create(:organization)) }
  let(:group)  { create(:group, follow_up_possible: 'yes') }

  context 'when login as customer' do
    before do
      travel(-4.days)
      visit "#ticket/zoom/#{ticket.id}"
      travel_back
    end

    context 'when ticket is closed and groups.follow_up_possible is "yes"' do
      let(:group) { create(:group, follow_up_possible: 'yes') }

      it 'show sidebar not as read only' do
        within(:active_content) do
          expect(page).to have_css('.sidebar [name=state_id]')
          expect(page).to have_no_css('.sidebar [name=state_id]:disabled')
        end
      end
    end

    context 'when ticket is closed and groups.follow_up_possible is "new_ticket"' do
      let(:group) { create(:group, follow_up_possible: 'new_ticket') }

      it 'show sidebar as read only' do
        within(:active_content) do
          expect(page).to have_css('.sidebar [name=state_id]:disabled')
        end
      end
    end

    context 'when ticket is closed and groups.follow_up_possible is "new_ticket_after_certain_time" but reopen is possible' do
      let(:group) { create(:group, follow_up_possible: 'new_ticket_after_certain_time', reopen_time_in_days: 5) }

      it 'show sidebar not as read only' do
        within(:active_content) do
          expect(page).to have_css('.sidebar [name=state_id]')
          expect(page).to have_no_css('.sidebar [name=state_id]:disabled')
        end
      end
    end

    context 'when ticket is closed and groups.follow_up_possible is "new_ticket_after_certain_time" reopen is not possible' do
      let(:group) { create(:group, follow_up_possible: 'new_ticket_after_certain_time', reopen_time_in_days: 4) }

      it 'show sidebar as read only' do
        within(:active_content) do
          expect(page).to have_css('.sidebar [name=state_id]:disabled')
        end
      end
    end
  end

end
