# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::Overview::TicketCount do
  let(:group)  { create(:group) }
  let(:listed) { create(:group) }
  let(:agent)  { create(:agent) }

  before do
    agent.group_ids_access_map = { group.id => 'full', listed.id => 'overview' }
    create_list(:ticket, 2, group:)
    create(:ticket, group: listed)
  end

  it 'counts the tickets the overview lists, without those the user may see in overviews only' do
    expect(described_class.with_current_user(agent).execute(overview: Overview.find_by(link: 'all_open'))).to eq(2)
  end

  it 'counts none for an overview whose condition cannot be read' do
    overview = create(:overview, role_ids: [Role.find_by(name: 'Agent').id])
    overview.update_column(:condition, { 'ticket.owner_id' => { 'operator' => 'is', 'pre_condition' => 'specific', 'value' => [] } })

    expect(described_class.with_current_user(agent).execute(overview:)).to eq(0)
  end
end
