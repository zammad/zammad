# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'services/service/ai/tool/field_scope_examples'

RSpec.describe Service::AI::Tool::SearchOrganizations, :aggregate_failures do
  let(:group)  { create(:group) }
  let(:agent)  { create(:agent, groups: [group]) }
  let(:token)  { create(:token, user: agent, preferences: { permission: %w[ticket.agent] }) }
  let!(:acme)  { create(:organization, name: 'Acme Ltd.', domain: 'acme.example', vip: true) }

  def call(arguments, user: agent, token: self.token)
    Service::MCPServer::CallTool.execute(tool: described_class, arguments:, user:, token:).to_h
  end

  def perform(arguments, user: agent, token: self.token)
    tool_call = AI::Provider::Completion::ToolCall.new(id: 'call_1', name: described_class.tool_name, arguments:)

    Service::AI::Tool::Runtime::PerformCall.execute(user:, tool_call:, surface: :mcp, token:)
  end

  def found_ids(arguments)
    perform(arguments).content[:organizations].pluck(:id)
  end

  before do
    Setting.set('http_type', 'https')
    Setting.set('fqdn', 'support.example.com')
    create(:customer, organization: acme)
    create(:customer, organization: create(:organization), organizations: [acme])
  end

  it 'is offered to an agent in the harness and over MCP, and to no customer\'s token' do
    customer       = create(:customer, organization: acme)
    customer_token = create(:token, user: customer, preferences: { permission: %w[ticket.agent ticket.customer] })

    expect(Service::AI::Tool::Runtime::Router.offered_tools(surface: :harness, user: agent, audience: AI::Harness::Audience::HUMAN_AGENTS)).to include(described_class)
    expect(Service::AI::Tool::Runtime::Router.offered_tools(user: agent, surface: :mcp, token:)).to include(described_class)
    expect(Service::AI::Tool::Runtime::Router.offered_tools(user: customer, surface: :mcp, token: customer_token)).not_to include(described_class)
  end

  it 'finds an organization by a part of the name and by the domain, as a row with its members counted' do
    %w[acme acme.example].each do |query|
      expect(call({ query: })[:structuredContent]).to eq(
        'query'         => query,
        'organizations' => [
          {
            'type'         => 'Organization',
            'id'           => acme.id,
            'name'         => 'Acme Ltd.',
            'domain'       => 'acme.example',
            'vip'          => true,
            'member_count' => 2,
            'url'          => "https://support.example.com/#organization/profile/#{acme.id}",
          },
        ],
        'has_more'      => false,
      ), query
    end
  end

  it 'fits its output schema' do
    errors = output_schema_errors(described_class.tool_output_schema, call({ query: 'acme' })[:structuredContent])

    expect(errors).to be_empty, errors.first(3).join(' | ')
  end

  it 'gives the model the same facts as text, and the way to the details' do
    expect(perform({ query: 'acme' }).text).to eq(<<~TEXT.chomp)
      Organizations matching "acme":

      - Acme Ltd. (domain acme.example, VIP, 2 members), organization ID #{acme.id}

      No more follow.

      get_organization reads an organization in detail by its ID: its note, custom fields and members. search_tickets lists an organization's tickets with organization "ID n".
    TEXT
  end

  it 'sorts by the field and direction asked for' do
    older = create(:organization, name: 'Acme Holding', created_at: 1.year.ago)

    expect(found_ids({ query: 'acme', sort_by: 'created_at', order_by: 'asc' })).to eq([older.id, acme.id])
    expect(found_ids({ query: 'acme', sort_by: 'name', order_by: 'desc' })).to eq([acme.id, older.id])
  end

  it 'lists an inactive organization marked, and one without members' do
    former = create(:organization, name: 'Acme Holding', active: false)

    expect(perform({ query: 'acme' }).content[:organizations].find { |row| row[:id] == former.id }).to include(member_count: 0, active: false)
    expect(perform({ query: 'acme' }).text).to include("- Acme Holding (0 members, inactive), organization ID #{former.id}")
  end

  it 'answers nothing found as a result, not an error' do
    result = perform({ query: 'Globex' })

    expect(result.status).to eq('ok')
    expect(result.content).to eq(query: 'Globex', organizations: [], has_more: false)
    expect(result.text).to eq("Organizations matching \"Globex\": none. #{Service::AI::Tool::Concerns::RecordSearch::NONE_HINT}")
  end

  it 'refuses a query without a word, as it would list every organization' do
    ['', '*'].each do |query|
      expect(perform({ query: }).content).to include(error: 'invalid_arguments'), query.inspect
    end
  end

  it 'pages with the cursor and refuses the cursor of another query' do
    create_list(:organization, 11, note: 'Pager')

    first = perform({ query: 'pager' }).content
    expect(first[:organizations].size).to eq(10)
    expect(first).to include(has_more: true, next_cursor: be_present)

    second = perform({ query: 'pager', cursor: first[:next_cursor] }).content
    expect(second[:organizations].size).to eq(1)
    expect(first[:organizations].pluck(:id) & second[:organizations].pluck(:id)).to be_empty

    expect(perform({ query: 'acme', cursor: first[:next_cursor] }).content).to include(error: 'invalid_arguments', message: include('cursor'))
  end

  it 'is not offered to a token without the agent permission' do
    calendar = create(:token, user: agent, preferences: { permission: %w[user_preferences.calendar] })

    expect(perform({ query: 'acme' }, token: calendar).content).to include(error: 'unknown_tool')
  end

  context 'when the policy shows the organization with a field scope only' do
    let(:reader) { agent }

    before do
      scope = ApplicationPolicy::FieldScope.new(allow: %i[id name active])

      allow(OrganizationPolicy).to receive(:new).and_wrap_original do |original, *args|
        original.call(*args).tap { |policy| allow(policy).to receive(:show?).and_return(scope) }
      end
    end

    it 'leaves out the domain and the VIP flag the scope denies' do
      expect(perform({ query: 'acme' }).content[:organizations].sole.keys).to contain_exactly(:type, :id, :name, :member_count)
    end

    it_behaves_like 'an AI tool returning only the fields the reader may see' do
      let(:tool_result) { perform({ query: 'acme' }) }
    end
  end

  context 'with Elasticsearch', searchindex: true do
    before do
      create(:organization, name: 'Globex Corporation', domain: 'globex.example')
      searchindex_model_reload([User, Organization])
    end

    it 'finds organizations by a word of the name and by the domain, as the search bar does' do
      expect(found_ids({ query: 'Acme' })).to eq([acme.id])
      expect(found_ids({ query: 'acme.example' })).to eq([acme.id])
      expect(found_ids({ query: 'Globex' })).not_to include(acme.id)
    end

    it 'sorts in the order asked for' do
      older = create(:organization, name: 'Acme Holding', created_at: 1.year.ago)
      searchindex_model_reload([Organization])

      expect(found_ids({ query: 'acme', sort_by: 'created_at', order_by: 'asc' })).to eq([older.id, acme.id])
      expect(found_ids({ query: 'acme', sort_by: 'name', order_by: 'desc' })).to eq([acme.id, older.id])
    end
  end
end
