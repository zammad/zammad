# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::ListTags, :aggregate_failures do
  let(:agent) { create(:agent) }
  let(:token) { create(:token, user: agent, preferences: { permission: %w[ticket.agent] }) }

  before do
    Tag::Item.destroy_all
    %w[Billing Billing-Q4 Invoice VIP].each { |name| Tag::Item.lookup_by_name_and_create(name) }
    create_list(:ticket, 2).each { |ticket| ticket.tag_add('VIP', 1) }
    create(:ticket).tag_add('Invoice', 1)
  end

  def call(arguments = {})
    Service::MCPServer::CallTool.execute(tool: described_class, arguments:, user: agent, token:).to_h
  end

  it "is offered to an agent's token over MCP only, as a read" do
    expect(Service::AI::Tool::Runtime::Router.offered_tools(user: agent, surface: :mcp, token:)).to include(described_class)
    expect(Service::AI::Tool::Runtime::Router.offered_tools(surface: :harness, user: agent, audience: AI::Harness::Audience::HUMAN_AGENTS)).not_to include(described_class)
    expect(Service::AI::Tool::Runtime::Router.offered_tools(user: create(:customer), surface: :mcp, token: create(:token))).not_to include(described_class)
  end

  it 'lists the tags, the most used first' do
    result = call

    expect(result[:structuredContent]).to eq('tags' => %w[VIP Invoice Billing Billing-Q4], 'total' => 4)
    expect(output_schema_errors(described_class.tool_output_schema, result[:structuredContent])).to be_empty
    expect(result[:content].first[:text]).to include('VIP, Invoice, Billing, Billing-Q4', 'No more follow.')
  end

  it 'narrows them by a part of the name, without regard to case' do
    expect(call({ query: 'BILL' })[:structuredContent]).to eq('tags' => %w[Billing Billing-Q4], 'total' => 2)
    expect(call({ query: 'nothing' })[:content].first[:text]).to eq('Tags: none match.')
  end

  it 'pages with a cursor that belongs to its query' do
    first  = call({ limit: 3 })[:structuredContent]
    second = call({ limit: 3, cursor: first['next_cursor'] })[:structuredContent]

    expect(first).to include('tags' => %w[VIP Invoice Billing], 'total' => 4)
    expect(second).to eq('tags' => ['Billing-Q4'], 'total' => 4)
    expect(call({ query: 'bill', limit: 3, cursor: first['next_cursor'] })[:content].first[:text]).to include('cursor is no next_cursor')
  end
end
