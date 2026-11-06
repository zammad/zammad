# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::GetCurrentUser, :aggregate_failures do
  let(:support)      { create(:group, name: 'Support') }
  let(:sales)        { create(:group, name: 'Sales') }
  let(:second_level) { create(:group, name: '2nd Level', parent: support) }
  let(:organization) { create(:organization, name: 'Example Corp') }
  let(:agent)        { create(:agent, firstname: 'Nina', lastname: 'Agent', email: 'nina@example.com', organization:, groups: [support], preferences: { locale: 'de-de' }) }
  let(:token)        { create(:token, user: agent, preferences: { permission: %w[ticket.agent knowledge_base.reader] }) }

  def call(token: self.token, user: agent)
    Service::MCPServer::CallTool.execute(tool: described_class, arguments: {}, user:, token:).to_h
  end

  before do
    Setting.set('http_type', 'https')
    Setting.set('fqdn', 'support.example.com')
    Setting.set('timezone_default', 'Europe/Berlin')
    agent.group_ids_access_map = { support.id => 'full', sales.id => %w[read change], second_level.id => 'overview' }
    create(:knowledge_base)
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

  it 'names the user with the link, the groups with their kind of access and the knowledge base level' do
    expect(call[:structuredContent]).to eq(
      'user'           => { 'type' => 'User', 'id' => agent.id, 'name' => 'Nina Agent', 'email' => 'nina@example.com', 'url' => "https://support.example.com/#user/profile/#{agent.id}" },
      'organization'   => { 'type' => 'Organization', 'id' => organization.id, 'name' => 'Example Corp', 'url' => "https://support.example.com/#organization/profile/#{organization.id}" },
      'locale'         => 'de-de',
      'time_zone'      => 'Europe/Berlin',
      'groups'         => [
        { 'name' => 'Sales', 'access' => %w[read change] },
        { 'name' => 'Support', 'access' => ['full'] },
        { 'name' => 'Support › 2nd Level', 'access' => ['overview'] },
      ],
      'knowledge_base' => 'reader',
    )
  end

  it 'fits its output schema' do
    expect(output_schema_errors(described_class.tool_output_schema, call[:structuredContent])).to be_empty
  end

  it 'gives the model the same facts as text, with the links below it' do
    expect(call.dig(:content, 0, :text)).to eq(<<~TEXT.chomp)
      Connected as Nina Agent (nina@example.com), user ID #{agent.id} · organization Example Corp.
      Language de-de · times in the tools' results are in Europe/Berlin.
      Groups: Sales (read, change) · Support (full) · Support › 2nd Level (overview)
      Knowledge base: reader — the internally and publicly published answers.

      Links:
      User #{agent.id}: https://support.example.com/#user/profile/#{agent.id}
      Organization #{organization.id}: https://support.example.com/#organization/profile/#{organization.id}
    TEXT
  end

  it 'counts the groups a role gives, and leaves out a deactivated one' do
    role = create(:role, permission_names: %w[ticket.agent])
    role.group_ids_access_map = { create(:group, name: 'Billing').id => 'create' }
    agent.roles << role
    second_level.update!(active: false)

    expect(call.dig(:structuredContent, 'groups')).to eq(
      [{ 'name' => 'Billing', 'access' => ['create'] }, { 'name' => 'Sales', 'access' => %w[read change] }, { 'name' => 'Support', 'access' => ['full'] }],
    )
  end

  it 'says so for an agent without groups' do
    agent.group_ids_access_map = {}

    expect(call[:structuredContent]).to include('groups' => [])
    expect(call.dig(:content, 0, :text)).to include('Groups: none — the user works with no group\'s tickets.')
  end

  describe 'the knowledge base level' do
    let(:editor) { create(:admin, groups: [support]) }

    def level(permissions, user: editor)
      call(user:, token: create(:token, user:, preferences: { permission: permissions })).dig(:structuredContent, 'knowledge_base')
    end

    it 'is what the token grants, not what the user\'s roles do' do
      expect(level(%w[ticket.agent knowledge_base.editor])).to eq('editor')
      expect(level(%w[ticket.agent knowledge_base.reader])).to eq('reader')
      expect(level(%w[ticket.agent])).to eq('published')
    end

    it 'is what the token and the user both hold' do
      expect(level(%w[ticket.agent knowledge_base.editor], user: agent)).to eq('published')
    end

    it 'is missing where no knowledge base is active' do
      KnowledgeBase.update_all(active: false)

      expect(call[:structuredContent]).not_to have_key('knowledge_base')
      expect(call.dig(:content, 0, :text)).not_to include('Knowledge base')
    end
  end
end
