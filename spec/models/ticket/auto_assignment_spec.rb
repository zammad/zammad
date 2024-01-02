# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket: #auto_assign' do # rubocop:disable RSpec/DescribeClass
  before do
    Setting.set('ticket_auto_assignment', ticket_auto_assignment)
    Setting.set('ticket_auto_assignment_selector', { condition: ticket_auto_assignment_condition })
  end

  context 'when auto assignment is enabled' do
    let(:ticket_auto_assignment) { true }

    context 'when conditions with states are used' do
      let(:ticket) { create(:ticket, group: Group.first, state: Ticket::State.find_by(name: 'closed')) }
      let(:agent)  { create(:agent, groups: [Group.first]) }

      context 'when the condition does match' do
        let(:ticket_auto_assignment_condition) { { 'ticket.state_id' => { operator: 'is', value: Ticket::State.pluck(:id) } } }

        it 'does auto assign' do
          ticket.auto_assign(agent)
          expect(ticket.reload.owner_id).to eq(agent.id)
        end
      end

      context 'when the condition does not match' do
        let(:ticket_auto_assignment_condition) { { 'ticket.state_id' => { operator: 'is', value: Ticket::State.by_category_ids(:work_on) } } }

        it 'does not auto assign' do
          ticket.auto_assign(agent)
          expect(ticket.reload.owner_id).to eq(1)
        end
      end
    end

    context 'when conditions with title are used' do
      let(:ticket) { create(:ticket, group: Group.first, title: 'Welcome to Zammad') }
      let(:agent)  { create(:agent, groups: [Group.first]) }

      context 'when the condition does match' do
        let(:ticket_auto_assignment_condition) { { 'ticket.title' => { operator: 'matches regex', value: '^welcome' } } }

        it 'does auto assign' do
          ticket.auto_assign(agent)
          expect(ticket.reload.owner_id).to eq(agent.id)
        end
      end

      context 'when the condition does not match' do
        let(:ticket_auto_assignment_condition) { { 'ticket.title' => { operator: 'does not match regex', value: '^welcome' } } }

        it 'does not auto assign' do
          ticket.auto_assign(agent)
          expect(ticket.reload.owner_id).to eq(1)
        end
      end
    end
  end
end
