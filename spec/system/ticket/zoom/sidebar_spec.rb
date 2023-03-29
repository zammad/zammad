# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > Sidebar', authenticated_as: :user, time_zone: 'Europe/London', type: :system do
  let(:ticket) do
    ticket = create(:ticket, customer: customer, group: group)

    travel_to close_time do
      ticket.update! state: Ticket::State.find_by(name: 'closed')
    end

    ticket
  end

  let(:customer)   { create(:customer, organization: create(:organization)) }
  let(:close_time) { Time.current }

  describe 're-openability of a closed ticket' do
    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    let(:state_elem) { find('.sidebar [name=state_id]') }

    shared_examples 'shows sidebar as read only' do
      it 'shows sidebar as read only' do
        within(:active_content) do
          expect(state_elem).to match_css(':disabled')
        end
      end
    end

    shared_examples 'shows sidebar as updatable' do
      it 'shows sidebar as updatable' do
        within(:active_content) do
          expect(state_elem).to match_css(':enabled')
        end
      end
    end

    shared_examples 'check roles' do |customer:, agent:, agent_customer:|
      context 'when user is customer' do
        let(:user) { ticket.customer }

        include_examples customer ? 'shows sidebar as updatable' : 'shows sidebar as read only'
      end

      context 'when user is agent' do
        let(:user) { create(:agent, groups: [ticket.group]) }

        include_examples agent ? 'shows sidebar as updatable' : 'shows sidebar as read only'
      end

      context 'when user is agent-customer' do
        let(:user)     { create(:agent_and_customer) }
        let(:customer) { user }

        include_examples agent_customer ? 'shows sidebar as updatable' : 'shows sidebar as read only'
      end
    end

    context 'when ticket is closed and groups.follow_up_possible is "yes"' do
      let(:group) { create(:group, follow_up_possible: 'yes') }

      include_examples 'check roles', customer: true, agent: true, agent_customer: true
    end

    context 'when ticket is closed and groups.follow_up_possible is "new_ticket"' do
      let(:group) { create(:group, follow_up_possible: 'new_ticket') }

      include_examples 'check roles', customer: false, agent: true, agent_customer: false
    end

    context 'when ticket is closed and groups.follow_up_possible is "new_ticket_after_certain_time"' do
      let(:group) { create(:group, follow_up_possible: 'new_ticket_after_certain_time', reopen_time_in_days: 5) }

      context 'when ticket was closed within the timeframe' do
        let(:close_time) { 3.days.ago }

        include_examples 'check roles', customer: true, agent: true, agent_customer: true
      end

      context 'when ticket was closed outside of the timeframe' do
        let(:close_time) { 1.month.ago }

        include_examples 'check roles', customer: false, agent: true, agent_customer: false
      end
    end
  end
end
