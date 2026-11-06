# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'services/service/ai/tool/field_scope_examples'

RSpec.describe Service::AI::Tool::GetOrganization, :aggregate_failures do
  let(:group)        { create(:group) }
  let(:agent)        { create(:agent, groups: [group]) }
  let(:organization) { create(:organization, name: 'Example Corp', vip: true, domain: 'example.com', domain_assignment: true, shared: true, note: 'Contract until 2027.') }
  let(:token)        { create(:token, user: agent, preferences: { permission: %w[ticket.agent] }) }
  let!(:anna)        { create(:customer, firstname: 'Anna', lastname: 'Example', email: 'anna@example.com', organization:, vip: true) }
  let!(:ben)         { create(:customer, firstname: 'Ben', lastname: 'Example', email: 'ben@example.com', organization: create(:organization), organizations: [organization], active: false) }

  def call(arguments, token: self.token)
    Service::MCPServer::CallTool.execute(tool: described_class, arguments:, user: agent, token:).to_h
  end

  def perform(arguments, token: self.token)
    tool_call = AI::Provider::Completion::ToolCall.new(id: 'call_1', name: described_class.tool_name, arguments:)

    Service::AI::Tool::Runtime::PerformCall.execute(user: agent, tool_call:, surface: :mcp, token:)
  end

  before do
    Setting.set('http_type', 'https')
    Setting.set('fqdn', 'support.example.com')
  end

  it 'is offered to an agent in the harness and over MCP, and to no customer\'s token' do
    customer_token = create(:token, user: anna, preferences: { permission: %w[ticket.agent ticket.customer] })

    expect(Service::AI::Tool::Runtime::Router.offered_tools(surface: :harness, user: agent, audience: AI::Harness::Audience::HUMAN_AGENTS)).to include(described_class)
    expect(Service::AI::Tool::Runtime::Router.offered_tools(user: agent, surface: :mcp, token:)).to include(described_class)
    expect(Service::AI::Tool::Runtime::Router.offered_tools(user: anna, surface: :mcp, token: customer_token)).not_to include(described_class)
  end

  it 'reads the organization with its domain, its record and its members, those of a secondary organization included' do
    base = 'https://support.example.com/#'

    expect(call({ organization_id: organization.id })[:structuredContent]).to eq(
      'organization' => {
        'type'              => 'Organization',
        'id'                => organization.id,
        'name'              => 'Example Corp',
        'domain'            => 'example.com',
        'domain_assignment' => true,
        'shared'            => true,
        'member_count'      => 2,
        'members'           => [
          { 'type' => 'User', 'id' => anna.id, 'name' => 'Anna Example', 'email' => 'anna@example.com', 'vip' => true, 'url' => "#{base}user/profile/#{anna.id}" },
          { 'type' => 'User', 'id' => ben.id, 'name' => 'Ben Example', 'email' => 'ben@example.com', 'active' => false, 'url' => "#{base}user/profile/#{ben.id}" },
        ],
        'vip'               => true,
        'note'              => 'Contract until 2027.',
        'url'               => "#{base}organization/profile/#{organization.id}",
      },
    )
  end

  it 'fits its output schema in both layers' do
    %w[detailed concise].each do |response_format|
      errors = output_schema_errors(described_class.tool_output_schema, call({ organization_id: organization.id, response_format: })[:structuredContent])

      expect(errors).to be_empty, "#{response_format}: #{errors.first(3).join(' | ')}"
    end
  end

  it 'gives the model the same facts as text, the note marked and the way to the members' do
    expect(perform({ organization_id: organization.id }).text).to eq(<<~TEXT.chomp)
      Organization Example Corp (ID #{organization.id}) · domain example.com · new users of the domain join it · members see each other's tickets · VIP · 2 members

      #{AI::PromptText.marked_text('Contract until 2027.', source: 'organization', field: 'note')}

      Members:
      - Anna Example (anna@example.com, VIP), user ID #{anna.id}
      - Ben Example (ben@example.com, inactive), user ID #{ben.id}

      get_user reads a member in detail by email or ID: phone, mobile, note.
    TEXT
  end

  it 'counts the members in the concise layer without listing them' do
    result = perform({ organization_id: organization.id, response_format: 'concise' })

    expect(result.content[:organization]).to include(member_count: 2, note: 'Contract until 2027.')
    expect(result.content[:organization]).not_to have_key(:members)
    expect(result.text).to end_with('The detailed layer lists the first members.')
  end

  it 'lists the first ten members and says how many there are' do
    create_list(:customer, 10, organization:)
    result = perform({ organization_id: organization.id })

    expect(result.content[:organization][:members].size).to eq(10)
    expect(result.content[:organization][:member_count]).to eq(12)
    expect(result.text).to include('12 members', 'Members: the first 10 of 12.')
  end

  it 'names an organization without members, domain and record' do
    empty = create(:organization, name: 'Quiet Ltd', active: false, shared: false)

    expect(perform({ organization_id: empty.id }).text).to eq("Organization Quiet Ltd (ID #{empty.id}) · inactive · 0 members")
  end

  it 'answers an organization that does not exist as not found, and needs its ID' do
    expect(perform({ organization_id: 0 }).content).to eq(error: 'not_found', message: Service::AI::Tool::NOT_FOUND_MESSAGE)
    expect(perform({}).content).to eq(error: 'invalid_arguments', message: Service::AI::Tool::Locator::Organization::NO_NAME)
  end

  context 'when the policies show the organization and its members with a field scope only' do
    let(:reader) { agent }

    before do
      { OrganizationPolicy => %i[id name active], UserPolicy => %i[id firstname lastname image image_source active] }.each do |policy_class, allowed|
        scope = ApplicationPolicy::FieldScope.new(allow: allowed)

        allow(policy_class).to receive(:new).and_wrap_original do |original, *args|
          original.call(*args).tap { |policy| allow(policy).to receive(:show?).and_return(scope) }
        end
      end
    end

    it 'leaves out the record and every detail the scope denies, of the members too' do
      content = perform({ organization_id: organization.id }).content[:organization]

      expect(content.keys).to contain_exactly(:type, :id, :name, :member_count, :members)
      expect(content[:members]).to eq([{ type: 'User', id: anna.id, name: 'Anna Example' }, { type: 'User', id: ben.id, name: 'Ben Example', active: false }])
    end

    it_behaves_like 'an AI tool returning only the fields the reader may see' do
      let(:tool_result) { perform({ organization_id: organization.id }) }
    end
  end
end
