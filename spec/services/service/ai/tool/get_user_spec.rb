# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'services/service/ai/tool/field_scope_examples'

RSpec.describe Service::AI::Tool::GetUser, :aggregate_failures do
  let(:group)        { create(:group) }
  let(:agent)        { create(:agent, groups: [group]) }
  let(:organization) { create(:organization, name: 'Example Corp') }
  let(:branch)       { create(:organization, name: 'Branch Ltd') }
  let(:customer)     do
    create(:customer, firstname: 'Anna', lastname: 'Example', email: 'anna@example.com', phone: '+49 30 1234', mobile: '+49 170 5678',
                      organization:, organizations: [branch], vip: true, note: 'Prefers phone calls.', department: 'Sales')
  end
  let(:token)     { create(:token, user: agent, preferences: { permission: %w[ticket.agent] }) }
  let(:not_found) { { error: 'not_found', message: Service::AI::Tool::Locator::User::NOT_FOUND } }

  def call(arguments, user: agent, token: self.token)
    Service::MCPServer::CallTool.execute(tool: described_class, arguments:, user:, token:).to_h
  end

  def perform(arguments, user: agent, token: self.token)
    tool_call = AI::Provider::Completion::ToolCall.new(id: 'call_1', name: described_class.tool_name, arguments:)

    Service::AI::Tool::Runtime::PerformCall.execute(user:, tool_call:, surface: :mcp, token:)
  end

  before do
    Setting.set('http_type', 'https')
    Setting.set('fqdn', 'support.example.com')
  end

  it 'is offered to an agent in the harness and over MCP, and to no customer\'s token' do
    customer_token = create(:token, user: customer, preferences: { permission: %w[ticket.agent ticket.customer] })

    expect(Service::AI::Tool::Runtime::Router.offered_tools(surface: :harness, user: agent, audience: AI::Harness::Audience::HUMAN_AGENTS)).to include(described_class)
    expect(Service::AI::Tool::Runtime::Router.offered_tools(user: agent, surface: :mcp, token:)).to include(described_class)
    expect(Service::AI::Tool::Runtime::Router.offered_tools(user: customer, surface: :mcp, token: customer_token)).not_to include(described_class)
  end

  it 'reads the user by ID and by email, in any case, with how to reach them, their organizations and their record' do
    base = 'https://support.example.com/#'

    [{ user_id: customer.id }, { email: ' ANNA@example.com ' }].each do |arguments|
      expect(call(arguments)[:structuredContent]).to eq(
        'user' => {
          'type'          => 'User',
          'id'            => customer.id,
          'name'          => 'Anna Example',
          'email'         => 'anna@example.com',
          'phone'         => '+49 30 1234',
          'mobile'        => '+49 170 5678',
          'organization'  => { 'type' => 'Organization', 'id' => organization.id, 'name' => 'Example Corp', 'url' => "#{base}organization/profile/#{organization.id}" },
          'organizations' => [{ 'type' => 'Organization', 'id' => branch.id, 'name' => 'Branch Ltd', 'url' => "#{base}organization/profile/#{branch.id}" }],
          'vip'           => true,
          'fields'        => { 'department' => 'Sales' },
          'note'          => 'Prefers phone calls.',
          'url'           => "#{base}user/profile/#{customer.id}",
        },
      ), arguments.keys.first.to_s
    end
  end

  it 'fits its output schema in both layers' do
    %w[detailed concise].each do |response_format|
      errors = output_schema_errors(described_class.tool_output_schema, call({ user_id: customer.id, response_format: })[:structuredContent])

      expect(errors).to be_empty, "#{response_format}: #{errors.first(3).join(' | ')}"
    end
  end

  it 'gives the model the same facts as text, the record\'s texts marked and the way to the organizations' do
    expect(perform({ user_id: customer.id }).text).to eq(<<~TEXT.chomp)
      User Anna Example (ID #{customer.id}) · anna@example.com · phone +49 30 1234 · mobile +49 170 5678 · VIP
      organization Example Corp (ID #{organization.id}) · other organizations: Branch Ltd (ID #{branch.id})

      #{AI::PromptText.marked_text('Prefers phone calls.', source: 'customer_record', field: 'note')}

      #{AI::PromptText.marked_text('Sales', source: 'customer_record', field: 'department')}

      get_organization reads an organization in detail by its ID: its domain, VIP flag, note and members.
    TEXT
  end

  it 'leaves out the free-text fields in the concise layer and keeps the note' do
    content = perform({ user_id: customer.id, response_format: 'concise' }).content[:user]

    expect(content).to include(note: 'Prefers phone calls.', vip: true)
    expect(content).not_to have_key(:fields)
  end

  it 'says that a number is missing, and names an inactive user and one without an organization' do
    customer.update!(phone: '', mobile: nil, organization: nil, organizations: [], vip: false, note: '', department: nil, active: false)

    expect(perform({ user_id: customer.id }).text).to eq(<<~TEXT.chomp)
      User Anna Example (ID #{customer.id}) · anna@example.com · no phone · no mobile · inactive
      organization: none
    TEXT
    expect(perform({ user_id: customer.id }).content[:user]).to include(active: false)
    expect(perform({ user_id: customer.id }).content[:user]).not_to have_key(:phone)
  end

  it 'names the fax and the web where they are set' do
    customer.update!(fax: '+49 30 9999', web: 'https://example.com')

    expect(perform({ user_id: customer.id }).text.lines.first).to include('fax +49 30 9999 · web https://example.com')
  end

  it 'marks an agent\'s record as a user\'s, not a customer\'s' do
    agent.update!(note: 'Part-time, Mondays off.')

    expect(perform({ user_id: agent.id }).text).to include(AI::PromptText.marked_text('Part-time, Mondays off.', source: 'user_record', field: 'note'))
  end

  it 'lists at most ten other organizations and says how many more there are' do
    customer.update!(organizations: create_list(:organization, 12))
    content = perform({ user_id: customer.id }).content[:user]

    expect(content[:organizations].size).to eq(10)
    expect(content[:organizations_omitted]).to eq(2)
    expect(perform({ user_id: customer.id }).text).to include('and 2 more')
  end

  it 'answers a user that does not exist as not found, by ID and by email, and names the search that finds one by a part' do
    expect(perform({ user_id: 0 }).content).to eq(not_found)
    expect(perform({ email: 'nobody@example.com' }).content).to eq(not_found)
    expect(not_found[:message]).to include('search_users')
    expect(call({ email: 'nobody@example.com' })).to include(isError: true, content: [include(text: include(not_found[:message]))])
  end

  it 'asks for the ID where several users share the email' do
    Setting.set('user_email_multiple_use', true)
    create(:customer, email: customer.email)

    expect(perform({ email: customer.email }).content).to eq(error: 'ambiguous', message: Service::AI::Tool::Locator::User::SHARED_EMAIL)
    expect(perform({ user_id: customer.id }).status).to eq('ok')
  end

  it 'needs a name on both surfaces' do
    no_name = { error: 'invalid_arguments', message: Service::AI::Tool::Locator::User::NO_NAME }

    expect(perform({}).content).to eq(no_name)
    expect(described_class.argument_errors({}, surface: :harness)).to eq([Service::AI::Tool::Locator::User::NO_NAME])
  end

  it 'is not found for a token without the agent permission' do
    calendar = create(:token, user: agent, preferences: { permission: %w[user_preferences.calendar] })

    expect(perform({ user_id: customer.id }, token: calendar).content).to include(error: 'unknown_tool')
  end

  context 'when the policy shows the user with a field scope only' do
    let(:reader) { agent }

    before do
      scope = ApplicationPolicy::FieldScope.new(allow: %i[id firstname lastname image image_source active])

      allow(UserPolicy).to receive(:new).and_wrap_original do |original, *args|
        original.call(*args).tap { |policy| allow(policy).to receive(:show?).and_return(scope) }
      end
    end

    it 'leaves out the record and every contact field the scope denies' do
      content = perform({ user_id: customer.id }).content[:user]

      expect(content.keys).to contain_exactly(:type, :id, :name, :organization, :organizations)
      expect(perform({ user_id: customer.id }).text.lines.first.chomp).to eq("User Anna Example (ID #{customer.id})")
    end

    it_behaves_like 'an AI tool returning only the fields the reader may see' do
      let(:tool_result) { perform({ user_id: customer.id }) }
    end
  end
end
