# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::Overview::Tickets, :aggregate_failures do
  let(:group)  { create(:group) }
  let(:listed) { create(:group) }
  let(:agent)  { create(:agent) }

  def tickets(overview)
    described_class.with_current_user(agent).execute(overview:)
  end

  before do
    agent.group_ids_access_map = { group.id => 'full', listed.id => 'overview' }
  end

  it 'lists the overview\'s tickets in its order' do
    older = create(:ticket, group:, owner: agent, created_at: 2.days.ago)
    newer = create(:ticket, group:, owner: agent, created_at: 1.day.ago)

    expect(tickets(Overview.find_by(link: 'my_assigned')).to_a).to eq([older, newer])
  end

  it 'leaves out a ticket of a group the user may see in overviews only' do
    readable = create(:ticket, group:)
    create(:ticket, group: listed)

    expect(tickets(Overview.find_by(link: 'all_open')).to_a).to eq([readable])
  end

  it 'lists the tickets the user is mentioned in' do
    ticket = create(:ticket, group: listed)
    agent.group_ids_access_map = { group.id => 'full', listed.id => 'read' }
    create(:mention, mentionable: ticket, user: agent)

    expect(tickets(Overview.find_by(link: 'my_subscribed_tickets')).to_a).to eq([ticket])
  end

  it 'breaks ties by the ID, so that pages neither repeat nor skip a ticket' do
    overview = create(:overview, role_ids: [Role.find_by(name: 'Agent').id], order: { by: 'priority', direction: 'ASC' })
    created  = create_list(:ticket, 60, group:)

    pages = Array.new(6) { |page| tickets(overview).offset(page * 10).limit(10).map(&:id) }

    expect(pages.flatten).to eq(created.map(&:id).sort)
  end

  it 'sorts by an order the user chose instead of the overview\'s' do
    older = create(:ticket, group:, owner: agent, created_at: 2.days.ago)
    newer = create(:ticket, group:, owner: agent, created_at: 1.day.ago)

    expect(described_class.with_current_user(agent).execute(overview: Overview.find_by(link: 'my_assigned'), order_by: 'created_at', order_direction: 'DESC').to_a)
      .to eq([newer, older])
  end
end
