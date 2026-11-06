# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'services/service/ai/tool/loads_context_object_examples'

RSpec.describe Service::AI::Tool::SetTicketTags, :aggregate_failures do
  let(:group)  { create(:group) }
  let(:agent)  { create(:agent, groups: [group]) }
  let(:token)  { create(:token, user: agent, preferences: { permission: %w[ticket.agent] }) }
  let(:ticket) { create(:ticket, group:) }

  before do
    Setting.set('http_type', 'https')
    Setting.set('fqdn', 'support.example.com')
    %w[Billing VIP Invoice Dispute].each { |name| Tag::Item.lookup_by_name_and_create(name) }
  end

  def call(arguments, user: agent, token: self.token)
    Service::MCPServer::CallTool.execute(tool: described_class, arguments: { ticket_number: ticket.number }.merge(arguments), user:, token:).to_h
  end

  def text(result)
    result[:content].first[:text]
  end

  it "is offered to an agent's token over MCP only, as an idempotent destructive write of the closed world" do
    expect(Service::AI::Tool::Runtime::Router.offered_tools(user: agent, surface: :mcp, token:)).to include(described_class)
    expect(Service::AI::Tool::Runtime::Router.offered_tools(surface: :harness, user: agent, audience: AI::Harness::Audience::HUMAN_AGENTS)).not_to include(described_class)
    expect(Service::AI::Tool::Runtime::Router.offered_tools(user: agent, surface: :mcp, token: create(:token, user: agent, preferences: { permission: %w[user_preferences.calendar] }))).not_to include(described_class)

    annotations = Service::MCPServer::ToolDefinition.execute(tool: described_class, user: agent, token:).annotations
    expect(annotations.to_h).to eq(readOnlyHint: false, destructiveHint: true, idempotentHint: true, openWorldHint: false)
  end

  it "adds and removes tags by their existing names, as the token's user, and leaves the others" do
    ticket.tag_add('Dispute', 1)

    result = call({ add: ['billing', ' VIP '], remove: ['dispute'] })

    expect(result[:isError]).to be(false)
    expect(result[:structuredContent]).to eq(
      'ticket_id' => ticket.id, 'ticket_number' => ticket.number, 'url' => "https://support.example.com/#ticket/zoom/#{ticket.id}",
      'added' => %w[Billing VIP], 'removed' => ['Dispute'], 'already_set' => [], 'not_set' => [], 'created' => [], 'tags' => %w[Billing VIP]
    )
    expect(output_schema_errors(described_class.tool_output_schema, result[:structuredContent])).to be_empty
    expect(text(result)).to include('Added: Billing, VIP.', 'Removed: Dispute.', 'Tags now: Billing, VIP.')

    history = History.list('Ticket', ticket.id).select { |entry| entry['attribute'] == 'tag' }.last(3)
    expect(history.pluck('type', 'value_to', 'created_by_id')).to eq([['added', 'Billing', agent.id], ['added', 'VIP', agent.id], ['removed', 'Dispute', agent.id]])
  end

  it 'tells what was so already, and creates no tag for a removal' do
    ticket.tag_add('VIP', 1)

    expect { call({ add: ['vip'], remove: ['Gold'] }) }.not_to change(Tag::Item, :count)
    expect(call({ add: ['vip'], remove: ['Gold'] })[:structuredContent]).to include('added' => [], 'already_set' => ['VIP'], 'not_set' => ['Gold'], 'tags' => ['VIP'])
  end

  it 'refuses a name that matches no tag with the closest ones, and changes nothing' do
    result = nil
    expect { result = call({ add: %w[Billing invoice-dispute] }) }.not_to change(Tag::Item, :count)

    expect(text(result)).to include('invalid_value', '\"invoice-dispute\" matches no tag; the closest: Dispute, Invoice', 'Nothing was changed')
    expect(text(call({ add: ['Wombat'] }))).to include('\"Wombat\" matches no tag, and none is close')
    expect(ticket.tag_list).to be_empty
  end

  it 'takes no tag whose name only contains the name given' do
    Tag::Item.lookup_by_name_and_create('VIP-Gold')

    expect(text(call({ add: ['Gold'] }))).to include('the closest: VIP-Gold')
    expect(ticket.tag_list).to be_empty
  end

  it 'asks which of two tags that differ only by case is meant, unless one is named exactly' do
    Tag::Item.lookup_by_name_and_create('vip')

    expect(text(call({ add: ['Vip'] }))).to include('ambiguous', 'VIP', 'vip')
    expect(call({ add: ['vip'] })[:structuredContent]).to include('added' => ['vip'])
  end

  it 'removes the tag of the very name, or the only one on the ticket that differs by case' do
    Tag::Item.lookup_by_name_and_create('vip')
    ticket.tag_add('VIP', 1)

    expect(call({ remove: ['vip'] })[:structuredContent]).to include('removed' => [], 'not_set' => ['vip'], 'tags' => ['VIP'])

    ticket.tag_add('vip', 1)
    expect(text(call({ remove: ['Vip'] }))).to include('ambiguous', 'on this ticket')
    expect(ticket.tag_list).to contain_exactly('VIP', 'vip')

    ticket.tag_add('Billing', 1)
    expect(call({ remove: ['BILLING'] })[:structuredContent]).to include('removed' => ['Billing'])
  end

  context 'when the call asks for a new tag' do
    it 'creates it where new tags are allowed' do
      Setting.set('tag_new', true)

      expect(call({ add: ['Escalated'], create_new_tags: true })[:structuredContent]).to include('added' => ['Escalated'], 'created' => ['Escalated'])
      expect(Tag::Item.exists?(name: 'Escalated')).to be(true)
    end

    it 'refuses it where only existing tags may be used, unless the user and the token may administer tags' do
      Setting.set('tag_new', false)

      expect(text(call({ add: %w[Billing Escalated], create_new_tags: true }))).to include('not_allowed', 'only existing tags may be used', 'Nothing was changed')
      expect(ticket.tag_list).to be_empty
      expect(Tag::Item.exists?(name: 'Escalated')).to be(false)

      admin = create(:admin, groups: [group])
      call({ add: ['Escalated'], create_new_tags: true }, user: admin, token: create(:token, user: admin, preferences: { permission: %w[ticket.agent] }))
      expect(ticket.tag_list).to be_empty

      call({ add: ['Escalated'], create_new_tags: true }, user: admin, token: create(:token, user: admin, preferences: { permission: %w[ticket.agent admin.tag] }))
      expect(ticket.tag_list).to eq(['Escalated'])
    end

    it 'creates nothing without it, even where new tags are allowed' do
      Setting.set('tag_new', true)

      expect(text(call({ add: ['Escalated'] }))).to include('matches no tag')
      expect(Tag::Item.exists?(name: 'Escalated')).to be(false)
    end
  end

  it 'refuses calls that name nothing, too much, or a tag twice' do
    {
      {}                                     => 'Name at least one tag',
      { add: Array.new(21) { |i| "t#{i}" } } => 'at most 20',
      { add: [' '] }                         => 'A tag name is empty',
      { add: ['a,b'] }                       => 'no commas',
      { add: ['VIP'], remove: ['vip'] }      => 'to add and to remove at once',
      { add: %w[Escalated escalated] }       => 'differing by case only',
    }.each do |arguments, message|
      expect(text(call(arguments))).to include(message)
    end
  end

  it 'changes no ticket the user may only read, which it says, nor one they may not see' do
    readable = create(:ticket, group: create(:group))
    hidden   = create(:ticket, group: create(:group))
    agent.group_ids_access_map = { group.id => 'full', readable.group_id => 'read' }

    { readable => 'read_only', hidden => 'not_found' }.each do |other, error|
      expect(text(call({ ticket_number: other.number, add: ['VIP'] }))).to include(error)
      expect(other.tag_list).to be_empty
    end
  end

  it_behaves_like 'an AI tool loading a named ticket' do
    let(:tool)              { described_class }
    let(:user)              { agent }
    let(:readable_object)   { ticket }
    let(:unreadable_object) { create(:ticket) }
    let(:tool_arguments)    { { add: ['VIP'] } }
  end
end
