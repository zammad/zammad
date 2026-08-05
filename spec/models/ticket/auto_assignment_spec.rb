# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

    context 'when conditions are configured via expert mode (regression test for #6279)' do
      let(:ticket)          { create(:ticket, group: Group.first, priority: Ticket::Priority.find_by(name: '1 low')) }
      let(:matching_ticket) { create(:ticket, group: Group.first, priority: Ticket::Priority.find_by(name: '2 normal')) }
      let(:agent)           { create(:agent, groups: [Group.first]) }

      let(:ticket_auto_assignment_condition) do
        {
          operator:   'OR',
          conditions: [
            {
              operator:   'AND',
              conditions: [
                { name: 'ticket.group_id', operator: 'is', value: [Group.first.id.to_s] },
                { name: 'ticket.priority_id', operator: 'is not', value: [Ticket::Priority.find_by(name: '1 low').id.to_s] },
              ],
            },
          ],
        }
      end

      before do
        matching_ticket
      end

      context 'when the opened ticket does not match, but another ticket elsewhere does' do
        it 'does not auto assign' do
          ticket.auto_assign(agent)
          expect(ticket.reload.owner_id).to eq(1)
        end
      end

      context 'when the opened ticket does match' do
        let(:ticket) { create(:ticket, group: Group.first, priority: Ticket::Priority.find_by(name: '2 normal')) }

        it 'does auto assign' do
          ticket.auto_assign(agent)
          expect(ticket.reload.owner_id).to eq(agent.id)
        end
      end
    end
  end
end
