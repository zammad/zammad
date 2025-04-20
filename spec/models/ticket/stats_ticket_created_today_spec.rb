# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Stats::TicketCreatedToday' do
  let(:agent)  { create(:agent, groups: Group.all) }
  let(:ticket) { create(:ticket, group: Group.first, owner: agent) }

  it 'does calculate dashboard correctly' do
    create_list(:ticket, 5, group: Group.first, owner: agent)
    # Two creates for past tickets to prevent timeout
    create_list(:ticket, 180, group: Group.first, owner: agent, created_at: 3.days.ago)
    create_list(:ticket, 180, group: Group.first, owner: agent, created_at: 3.days.ago)

    Stats.generate
    expect(StatsStore.find_by(key: 'dashboard', stats_storable_type: 'User', stats_storable_id: agent.id).data['StatsTicketCreatedToday']).to eq({ 'tickets_today' => 6, 'daily_average' => 1 })
  end
end
