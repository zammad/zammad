# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket::CallsStatsTicketReopenLog' do
  let(:agent)  { create(:agent, groups: Group.all) }
  let(:ticket) { create(:ticket, group: Group.first, owner: agent) }

  it 'does track reopened tickets' do
    ticket.update(state: Ticket::State.find_by(name: 'closed'))
    ticket.update(state: Ticket::State.find_by(name: 'open'))
    expect(StatsStore.find_by(key: 'ticket:reopen', stats_storable_type: 'User', stats_storable_id: agent.id).data).to eq({ 'ticket_id'=> ticket.id })
  end

  it 'does calculate dashboard correctly' do
    create_list(:ticket, 8, group: Group.first, owner: agent, state: Ticket::State.find_by(name: 'closed'))
    tickets_reopened = create_list(:ticket, 2, group: Group.first, owner: agent, state: Ticket::State.find_by(name: 'closed'))
    tickets_reopened.each { |ticket| ticket.update(state: Ticket::State.find_by(name: 'open')) }

    Stats.generate
    expect(StatsStore.find_by(key: 'dashboard', stats_storable_type: 'User', stats_storable_id: agent.id).data['StatsTicketReopen']).to eq({ 'used_for_average' => 20.0, 'percent' => 20.0, 'average_per_agent' => 20.0, 'state' => 'good', 'count' => 2, 'total' => 10 })
  end
end
