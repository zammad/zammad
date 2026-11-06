# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'services/service/ai/tool/field_scope_examples'

RSpec.describe Service::AI::Tool::SearchUsers, :aggregate_failures do
  let(:group)        { create(:group) }
  let(:agent)        { create(:agent, groups: [group]) }
  let(:organization) { create(:organization, name: 'Acme Ltd.') }
  let(:token)        { create(:token, user: agent, preferences: { permission: %w[ticket.agent] }) }
  let!(:customer) do
    create(:customer, firstname: 'Max', lastname: 'Huber', email: 'max.huber@acme.example', login: 'mhuber', phone: '+49 30 123456',
                      mobile: '+49 170 5678', organization:, vip: true)
  end

  def call(arguments, user: agent, token: self.token)
    Service::MCPServer::CallTool.execute(tool: described_class, arguments:, user:, token:).to_h
  end

  def perform(arguments, user: agent, token: self.token)
    tool_call = AI::Provider::Completion::ToolCall.new(id: 'call_1', name: described_class.tool_name, arguments:)

    Service::AI::Tool::Runtime::PerformCall.execute(user:, tool_call:, surface: :mcp, token:)
  end

  def found_ids(arguments)
    perform(arguments).content[:users].pluck(:id)
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

  it 'finds a user by a part of the name, the email and the login, as a row with what tells them apart' do
    base = 'https://support.example.com/#'

    %w[hube max.huber@acme.example mhuber].each do |query|
      expect(call({ query: })[:structuredContent]).to eq(
        'query'    => query,
        'users'    => [
          {
            'type'         => 'User',
            'id'           => customer.id,
            'name'         => 'Max Huber',
            'email'        => 'max.huber@acme.example',
            'phone'        => '+49 30 123456',
            'mobile'       => '+49 170 5678',
            'organization' => { 'type' => 'Organization', 'id' => organization.id, 'name' => 'Acme Ltd.', 'url' => "#{base}organization/profile/#{organization.id}" },
            'vip'          => true,
            'url'          => "#{base}user/profile/#{customer.id}",
          },
        ],
        'has_more' => false,
      ), query
    end
  end

  it 'fits its output schema' do
    errors = output_schema_errors(described_class.tool_output_schema, call({ query: 'huber' })[:structuredContent])

    expect(errors).to be_empty, errors.first(3).join(' | ')
  end

  it 'finds and pages people by their full name without Elasticsearch' do
    namesake = create(:customer, firstname: 'Max', lastname: 'Huber')

    first = perform({ query: 'Max Huber', limit: 1 }).content
    second = perform({ query: 'Max Huber', limit: 1, cursor: first[:next_cursor] }).content

    expect(first).to include(has_more: true)
    expect(second).to include(has_more: false)
    expect([first, second].flat_map { |page| page[:users].pluck(:id) }).to contain_exactly(customer.id, namesake.id)
  end

  it 'sorts by the field and direction asked for' do
    aaron = create(:customer, firstname: 'Max', lastname: 'Aaron', active: false)

    expect(found_ids({ query: 'Max' })).to eq([customer.id, aaron.id])
    expect(found_ids({ query: 'Max', sort_by: 'lastname', order_by: 'asc' })).to eq([aaron.id, customer.id])
  end

  it 'gives the model the same facts as text, and the way to the details' do
    expect(perform({ query: 'huber' }).text).to eq(<<~TEXT.chomp)
      Users matching "huber":

      - Max Huber (max.huber@acme.example, phone +49 30 123456, mobile +49 170 5678, VIP), organization Acme Ltd. (ID #{organization.id}), user ID #{customer.id}

      No more follow.

      get_user reads a user in detail by ID or email: their other organizations, note and custom fields. search_tickets lists a user's tickets with customer "ID n".
    TEXT
  end

  it 'finds a phone number however it is written, through the numbers of the caller log' do
    ['+49 30 123456', '030 123456', '0049 (30) 123456', '+49-30-123456'].each do |query|
      expect(found_ids({ query: })).to eq([customer.id]), query
    end
  end

  it 'pages every user who shares a number, as a switchboard\'s number is shared' do
    sharing = create_list(:customer, 20, phone: '+49 30 123456')

    first  = perform({ query: '030 123456' }).content
    second = perform({ query: '030 123456', cursor: first[:next_cursor] }).content
    third  = perform({ query: '030 123456', cursor: second[:next_cursor] }).content

    expect([first, second, third].flat_map { |page| page[:users].pluck(:id) }).to contain_exactly(customer.id, *sharing.map(&:id))
    expect(third).to include(has_more: false)
  end

  it 'searches a number the caller log does not know as words' do
    customer.update!(note: 'Badge 4711 0815')

    expect(found_ids({ query: '4711 0815' })).to eq([customer.id])
  end

  it 'lists two people of the same name apart, and an inactive one marked' do
    namesake = create(:customer, firstname: 'Maria', lastname: 'Huber', email: 'maria@globex.example', active: false)

    content = perform({ query: 'huber' }).content
    expect(content[:users].pluck(:id)).to contain_exactly(customer.id, namesake.id)
    expect(content[:users].find { |row| row[:id] == namesake.id }).to include(email: 'maria@globex.example', active: false)
    expect(perform({ query: 'huber' }).text).to include("- Maria Huber (maria@globex.example, inactive), user ID #{namesake.id}")
  end

  it 'never finds the system user' do
    User.find(1).update_columns(note: 'Shared word')
    customer.update!(note: 'Shared word')

    expect(found_ids({ query: 'shared word' })).to eq([customer.id])
  end

  it 'excludes the system user before paging phone matches' do
    system_user = User.find(1)
    system_user.update!(phone: customer.phone)
    Cti::CallerId.add(system_user)

    result = perform({ query: customer.phone, limit: 1 }).content

    expect(result[:users].pluck(:id)).to eq([customer.id])
    expect(result).to include(has_more: false).and(not_include(:next_cursor))
  end

  it 'answers nothing found as a result, not an error' do
    result = perform({ query: 'Globex' })

    expect(result.status).to eq('ok')
    expect(result.content).to eq(query: 'Globex', users: [], has_more: false)
    expect(result.text).to eq("Users matching \"Globex\": none. #{Service::AI::Tool::Concerns::RecordSearch::NONE_HINT}")
  end

  it 'refuses a query without a word, as it would list every user' do
    ['', '   ', '*', '"*"'].each do |query|
      expect(perform({ query: }).content).to include(error: 'invalid_arguments'), query.inspect
    end
  end

  it 'pages with the cursor and refuses the cursor of another query' do
    create_list(:customer, 11, lastname: 'Pager')

    first = perform({ query: 'pager' }).content
    expect(first[:users].size).to eq(10)
    expect(first).to include(has_more: true, next_cursor: be_present)

    second = perform({ query: 'pager', cursor: first[:next_cursor] }).content
    expect(second[:users].size).to eq(1)
    expect(second).to include(has_more: false).and(not_include(:next_cursor))
    expect(first[:users].pluck(:id) & second[:users].pluck(:id)).to be_empty

    expect(perform({ query: 'huber', cursor: first[:next_cursor] }).content).to include(error: 'invalid_arguments', message: include('cursor'))
  end

  it 'takes a smaller page' do
    create_list(:customer, 3, lastname: 'Pager')

    expect(perform({ query: 'pager', limit: 2 }).content[:users].size).to eq(2)
  end

  it 'is not offered to a token without the agent permission' do
    calendar = create(:token, user: agent, preferences: { permission: %w[user_preferences.calendar] })

    expect(perform({ query: 'huber' }, token: calendar).content).to include(error: 'unknown_tool')
  end

  context 'when the policy shows the user with a field scope only' do
    let(:reader) { agent }

    before do
      scope = ApplicationPolicy::FieldScope.new(allow: %i[id firstname lastname image image_source active])

      allow(UserPolicy).to receive(:new).and_wrap_original do |original, *args|
        original.call(*args).tap { |policy| allow(policy).to receive(:show?).and_return(scope) }
      end
    end

    it 'leaves out every contact field and the VIP flag the scope denies' do
      expect(perform({ query: 'huber' }).content[:users].sole.keys).to contain_exactly(:type, :id, :name, :organization)
      expect(perform({ query: 'huber' }).text).to include("- Max Huber, organization Acme Ltd. (ID #{organization.id}), user ID #{customer.id}")
    end

    it_behaves_like 'an AI tool returning only the fields the reader may see' do
      let(:tool_result) { perform({ query: 'huber' }) }
    end
  end

  context 'with Elasticsearch', searchindex: true do
    before do
      create(:customer, firstname: 'Erika', lastname: 'Example', email: 'erika@globex.example')
      searchindex_model_reload([User, Organization])
    end

    it 'finds users by a word of the name, the email and the organization, as the search bar does' do
      expect(found_ids({ query: 'Huber' })).to eq([customer.id])
      expect(found_ids({ query: 'Max Huber' })).to eq([customer.id])
      expect(found_ids({ query: 'max.huber@acme.example' })).to eq([customer.id])
      expect(found_ids({ query: 'Acme' })).to eq([customer.id])
      expect(found_ids({ query: 'Globex' })).not_to include(customer.id)
    end

    it 'takes the search syntax' do
      expect(found_ids({ query: 'lastname:Huber' })).to eq([customer.id])
    end

    it 'sorts and pages in the order asked for' do
      aaron = create(:customer, firstname: 'Max', lastname: 'Aaron')
      searchindex_model_reload([User])

      first = perform({ query: 'Max', sort_by: 'lastname', order_by: 'asc', limit: 1 }).content
      last  = perform({ query: 'Max', sort_by: 'lastname', order_by: 'asc', limit: 1, cursor: first[:next_cursor] }).content

      expect([first, last].flat_map { |page| page[:users].pluck(:id) }).to eq([aaron.id, customer.id])
      expect(found_ids({ query: 'Max', sort_by: 'lastname', order_by: 'desc' })).to eq([customer.id, aaron.id])
    end

    it 'answers a query the search cannot run as a failed search' do
      expect(perform({ query: 'Huber AND (' }).content).to include(error: 'search_failed')
    end
  end
end
