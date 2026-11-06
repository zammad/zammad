# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::ListOverviews, :aggregate_failures do
  let(:support) { create(:group, name: 'Support') }
  let(:sales)   { create(:group, name: 'Sales') }
  let(:agent)   { create(:agent, firstname: 'Nina', lastname: 'Agent', groups: [support]) }
  let(:token)   { create(:token, user: agent, preferences: { permission: %w[ticket.agent] }) }

  let(:my_assigned) { Overview.find_by(link: 'my_assigned') }
  let(:unassigned)  { Overview.find_by(link: 'all_unassigned') }

  def call(token: self.token, user: agent)
    Service::MCPServer::CallTool.execute(tool: described_class, arguments: {}, user:, token:).to_h
  end

  def overviews(...)
    call(...)[:structuredContent]['overviews']
  end

  before do
    Setting.set('http_type', 'https')
    Setting.set('fqdn', 'support.example.com')
  end

  it 'is offered to an agent\'s token over MCP only' do
    expect(Service::AI::Tool::Runtime::Router.offered_tools(user: agent, surface: :mcp, token:)).to include(described_class)
    expect(Service::AI::Tool::Runtime::Router.offered_tools(surface: :harness, user: agent, audience: AI::Harness::Audience::HUMAN_AGENTS)).not_to include(described_class)
  end

  it 'is offered to no customer\'s token' do
    customer = create(:customer)
    token    = create(:token, user: customer, preferences: { permission: %w[ticket.agent ticket.customer] })

    expect(Service::AI::Tool::Runtime::Router.offered_tools(user: customer, surface: :mcp, token:)).not_to include(described_class)
  end

  it 'lists the agent\'s overviews as the overview list shows them, each with its count and link' do
    create(:ticket, group: support, owner: agent)
    create_list(:ticket, 2, group: support)

    expect(overviews.first(2)).to eq(
      [
        { 'type' => 'Overview', 'id' => my_assigned.id, 'name' => 'My Assigned Tickets', 'ticket_count' => 1, 'url' => 'https://support.example.com/#ticket/view/my_assigned' },
        { 'type' => 'Overview', 'id' => unassigned.id, 'name' => 'Unassigned & Open Tickets', 'ticket_count' => 2, 'url' => 'https://support.example.com/#ticket/view/all_unassigned' },
      ],
    )
    expect(overviews.pluck('name')).to eq(['My Assigned Tickets', 'Unassigned & Open Tickets', 'My Pending Reached Tickets', 'My Subscribed Tickets', 'Open Tickets', 'Pending Reached Tickets', 'Escalated Tickets'])
  end

  it 'fits its output schema' do
    expect(output_schema_errors(described_class.tool_output_schema, call[:structuredContent])).to be_empty
  end

  it 'gives the model the same facts as text, with the links below it' do
    create(:ticket, group: support, owner: agent)

    expect(call.dig(:content, 0, :text)).to start_with(<<~TEXT.chomp)
      Overviews, in the user's order:
      Overview #{my_assigned.id} · My Assigned Tickets · 1 ticket
      Overview #{unassigned.id} · Unassigned &amp; Open Tickets · no tickets
    TEXT
    expect(call.dig(:content, 0, :text)).to include(
      "get_overview_tickets reads the tickets of one by its ID or name.\n\nLinks:\nOverview #{my_assigned.id}: https://support.example.com/#ticket/view/my_assigned",
    )
  end

  it 'follows the user\'s own order' do
    create(:user_overview_sorting, overview: unassigned, prio: 1, user: agent)
    create(:user_overview_sorting, overview: my_assigned, prio: 2, user: agent)

    expect(overviews.pluck('id').first(2)).to eq([unassigned.id, my_assigned.id])
  end

  it 'names an overview in the user\'s language, with the stored name next to a translation' do
    agent.update!(preferences: { locale: 'de-de' })
    custom = create(:overview, name: 'VIP queue', role_ids: [Role.find_by(name: 'Agent').id], prio: 1)

    expect(overviews).to include(
      include('id' => my_assigned.id, 'name' => 'Meine zugewiesenen Tickets', 'stored_name' => 'My Assigned Tickets'),
      { 'type' => 'Overview', 'id' => custom.id, 'name' => 'VIP queue', 'ticket_count' => 0, 'url' => 'https://support.example.com/#ticket/view/vip_queue' },
    )
    expect(call.dig(:content, 0, :text)).to include("Overview #{my_assigned.id} · Meine zugewiesenen Tickets (My Assigned Tickets) · no tickets")
  end

  it 'counts only the tickets of groups the user may see' do
    create(:ticket, group: support, owner: agent)
    create(:ticket, group: sales, owner: agent)

    expect(overviews.find { |overview| overview['id'] == my_assigned.id }).to include('ticket_count' => 1)
  end

  it 'counts the tickets the token allows, not all its user may see' do
    agent.roles << Role.find_by(name: 'Customer')
    create(:ticket, group: sales, customer: agent)
    full = create(:token, user: agent, preferences: { permission: %w[ticket.agent ticket.customer] })

    expect(overviews(token: full).find { |overview| overview['name'] == 'My Tickets' }).to include('ticket_count' => 1)
    expect(overviews.find { |overview| overview['name'] == 'My Tickets' }).to include('ticket_count' => 0)
  end

  it 'leaves out an overview of another role, one restricted to other users, and an out-of-office one for no replacement' do
    restricted = create(:overview, name: 'Team lead queue', role_ids: [Role.find_by(name: 'Agent').id], user_ids: [create(:agent).id])
    admins     = create(:overview, name: 'Admin queue', role_ids: [Role.find_by(name: 'Admin').id])

    expect(overviews.pluck('id')).not_to include(restricted.id, admins.id, Overview.find_by(link: 'my_replacement_tickets').id)
  end

  it 'lists the out-of-office overview for a replacement' do
    create(:agent, :ooo, ooo_agent: agent)

    expect(overviews.pluck('name')).to include('My Replacement Tickets')
  end

  it 'lists an overview whose condition cannot be read with no tickets, and the others as they are' do
    broken = create(:overview, name: 'Broken', role_ids: [Role.find_by(name: 'Agent').id])
    broken.update_column(:condition, { 'ticket.owner_id' => { 'operator' => 'is', 'pre_condition' => 'specific', 'value' => [] } })

    expect(overviews).to include(include('id' => broken.id, 'ticket_count' => 0), include('id' => my_assigned.id))
  end

  it 'says so for a user without an overview' do
    Overview.destroy_all

    expect(overviews).to eq([])
    expect(call.dig(:content, 0, :text)).to eq('Overviews: none — the user has no overview in Zammad.')
  end
end
