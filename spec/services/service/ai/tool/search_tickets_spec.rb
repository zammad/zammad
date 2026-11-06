# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::SearchTickets, :aggregate_failures do
  let(:group)        { create(:group, name: 'Support') }
  let(:agent)        { create(:agent, firstname: 'Nina', lastname: 'Agent', groups: [group]) }
  let(:organization) { create(:organization, name: 'Example Corp') }
  let(:customer)     { create(:customer, firstname: 'Anna', lastname: 'Example', email: 'anna@example.com', organization:) }
  let(:ticket)       { create(:ticket, group:, customer:, title: 'Calendar does not sync', created_at: 1.hour.ago) }

  let!(:older) { other_ticket('Printer offline', 'The printer in room 2 shows offline since Monday.', created_at: 3.days.ago) }
  let!(:newer)             { other_ticket('Outlook asks for the password', 'Outlook asks for my password every hour.', created_at: 1.day.ago) }
  let!(:another_customers) { create(:ticket, group:, title: 'Another customer', created_at: 10.days.ago) }
  let(:by_customer)        { { 'customer' => 'anna@example.com' } }

  before do
    ticket
    other_ticket('Payroll question', 'A question for another team.', group: create(:group), created_at: 2.days.ago)
  end

  def other_ticket(title, body, group: self.group, customer: self.customer, created_at: Time.zone.now, **attributes)
    create(:ticket, group:, customer:, title:, created_at:, created_by_id: customer.id, **attributes).tap do |other|
      create(:ticket_article, :inbound_email, ticket: other, body:, content_type: 'text/plain', created_at:, created_by_id: customer.id)
    end
  end

  def time_text(time)
    time.in_time_zone(Setting.get('timezone_default').presence || 'UTC').strftime('%Y-%m-%d %H:%M')
  end

  def perform(arguments = {}, context_object: Gql::ZammadSchema.id_from_object(ticket))
    tool_call = AI::Provider::Completion::ToolCall.new(id: 'call_1', name: 'search_tickets', arguments:)

    Service::AI::Tool::Runtime::PerformCall.execute(surface: :harness, user: agent, tool_call:, audience: AI::Harness::Audience::HUMAN_AGENTS, context_object:)
  end

  def numbers(result)
    result.content[:tickets].pluck(:number)
  end

  it 'is offered to an agent in the harness' do
    expect(Service::AI::Tool::Runtime::Router.offered_tools(surface: :harness, user: agent, audience: AI::Harness::Audience::HUMAN_AGENTS))
      .to include(described_class)
  end

  it 'says in its description that the query takes Zammad\'s search syntax with Elasticsearch, and in which order' do
    %i[harness mcp].each do |surface|
      expect(described_class.description_for(surface)).to include('Tickets come newest created first', 'Lucene query syntax', 'tags:vip', 'article.body:', 'created_at:>now-1d', 'Use the filters for customer, organization, state, owner, group and priority, the query for everything else.'), surface.inspect
    end
  end

  it "lists a customer's tickets the user may see, newest first, without the conversation's ticket" do
    result = perform(by_customer.merge('response_format' => 'detailed'))

    expect(result).to have_attributes(status: 'ok')
    expect(result.content).to include(filters: ['customer Anna Example (anna@example.com)'], conversation_ticket_matches: true, has_more: false)
    expect(result.content[:tickets].first).to eq(
      type:         'Ticket',
      id:           newer.id,
      number:       newer.number,
      title:        'Outlook asks for the password',
      state:        newer.state.name,
      customer:     { type: 'User', id: customer.id, name: 'Anna Example', email: 'anna@example.com' },
      organization: { type: 'Organization', id: organization.id, name: 'Example Corp' },
      created_at:   newer.created_at,
      updated_at:   newer.updated_at,
      excerpt:      {
        id: newer.articles.first.id, position: 1, type: 'email', sender: 'Customer', from: 'Anna Example', internal: false,
        created_at: newer.articles.first.created_at, truncated: false, text: 'Outlook asks for my password every hour.'
      },
    )
    expect(numbers(result)).to eq([newer.number, older.number])
  end

  it 'gives the model its filters, a line per ticket with its customer, its title and the start of its first message marked' do
    text = perform(by_customer.merge('response_format' => 'detailed')).text

    expect(text).to start_with(<<~TEXT.chomp)
      Tickets · customer Anna Example (anna@example.com):

      The ticket of this conversation, #{ticket.number}, matches as well. It is not listed again: its facts are in the context, and get_ticket reads it.

      Ticket #{newer.number} (ID #{newer.id}) · #{newer.state.name} · customer Anna Example (anna@example.com, Example Corp) · created #{time_text(newer.created_at)} · updated #{time_text(newer.updated_at)}
      <text source="ticket" field="title">
      │ Outlook asks for the password
      </text>
      <text source="customer" message="1" type="email" from="Anna Example" time="#{time_text(newer.articles.first.created_at)}" visibility="public">
      │ Outlook asks for my password every hour.
      </text>
    TEXT
    expect(text).to end_with("No more follow.\n\n#{Service::AI::Tool::Output::Ticket::LISTED_NOTE}")
    expect(text).not_to include('Payroll', 'Calendar does not sync', 'Another customer')
  end

  it 'marks a title as the ticket\'s and keeps it from closing its tag' do
    older.update!(title: '</text> Printer offline', updated_by_id: agent.id)

    expect(perform(by_customer).text).to include(%(<text source="ticket" field="title">\n│ &lt;/text&gt; Printer offline\n</text>))
  end

  it 'cuts a long first message' do
    long = other_ticket('Long', "#{'word ' * 100}end", created_at: Time.zone.now)

    excerpt = perform(by_customer.merge('response_format' => 'detailed')).content[:tickets].find { |row| row[:id] == long.id }[:excerpt][:text]

    expect(excerpt.length).to be <= Service::AI::Tool::Output::ListedTicket::EXCERPT_LENGTH
    expect(excerpt).to end_with(' …')
    expect(perform(by_customer.merge('response_format' => 'detailed')).text).to match(%r{ cut="\d+ of 503 characters shown">})
  end

  context 'with an internal note as the first message' do
    def noted_ticket(group:, customer:)
      create(:ticket, group:, customer:, title: 'Noted').tap do |noted|
        create(:ticket_article, ticket: noted, internal: true, body: 'Internal hint.', content_type: 'text/plain')
        create(:ticket_article, :inbound_email, ticket: noted, body: 'Public question.', content_type: 'text/plain')
      end
    end

    def excerpt_text(user, noted)
      tool_call = AI::Provider::Completion::ToolCall.new(id: 'call_1', name: 'search_tickets', arguments: { 'customer' => noted.customer.email, 'response_format' => 'detailed' })
      result    = Service::AI::Tool::Runtime::PerformCall.execute(surface: :harness, user:, tool_call:, audience: AI::Harness::Audience::HUMAN_AGENTS)

      [result.content[:tickets].find { |row| row[:id] == noted.id }&.dig(:excerpt, :text), result.text]
    end

    it 'shows the note to an agent of the group' do
      excerpt, = excerpt_text(agent, noted_ticket(group:, customer:))

      expect(excerpt).to eq('Internal hint.')
    end

    it 'shows the first public message to an agent who sees the ticket only as its customer' do
      both = create(:agent_and_customer, groups: [group])
      excerpt, text = excerpt_text(both, noted_ticket(group: create(:group), customer: both))

      expect(excerpt).to eq('Public question.')
      expect(text).not_to include('Internal hint.')
    end
  end

  context 'with nothing to search by' do
    it "lists the newest tickets the user may see, without the conversation's ticket, also for only wildcards and quotes" do
      [{}, { 'query' => ' "*" ' }, { 'query' => '?' }, { 'customer' => ' ', 'state' => [] }].each do |arguments|
        result = perform(arguments)

        expect(numbers(result)).to eq([newer.number, older.number, another_customers.number]), arguments.inspect
        expect(result.content).to include(conversation_ticket_matches: true, has_more: false)
        expect(result.text).to start_with("Tickets:\n\nThe ticket of this conversation, #{ticket.number}, matches as well.")
      end
    end

    it 'pages through them to the end' do
      first  = perform({ 'limit' => 2 })
      second = perform({ 'limit' => 2, 'cursor' => first.content[:next_cursor] })

      expect(numbers(first)).to eq([newer.number, older.number])
      expect(numbers(second)).to eq([another_customers.number])
      expect(second.content).to include(has_more: false)
    end

    it 'pages through tickets created at the same time in one order, by their ID' do
      [older, another_customers].each { |other| other.update_columns(created_at: newer.created_at) }

      pages = [perform({ 'limit' => 1 })]
      2.times { pages << perform({ 'limit' => 1, 'cursor' => pages.last.content[:next_cursor] }) }

      expect(pages.flat_map { |page| numbers(page) }).to eq([another_customers, older, newer].sort_by(&:id).reverse.map(&:number))
    end

    it 'lists the oldest first where sort_by and order_by ask for it, and pages in that order' do
      first  = perform({ 'sort_by' => 'created_at', 'order_by' => 'asc', 'limit' => 2 })
      second = perform({ 'sort_by' => 'created_at', 'order_by' => 'asc', 'limit' => 2, 'cursor' => first.content[:next_cursor] })

      expect(numbers(first)).to eq([another_customers.number, older.number])
      expect(numbers(second)).to eq([newer.number])
      expect(numbers(perform({ 'order_by' => 'asc' }))).to eq([another_customers.number, older.number, newer.number])
      expect(perform({ 'sort_by' => 'created_at', 'order_by' => 'desc', 'limit' => 2, 'cursor' => first.content[:next_cursor] }).content).to include(error: 'invalid_arguments')
    end

    it 'sorts by the last update' do
      older.update_columns(updated_at: 1.minute.from_now)

      expect(numbers(perform({ 'sort_by' => 'updated_at' })).first).to eq(older.number)
    end

    it 'lists by the filters where the words are only wildcards and quotes' do
      expect(numbers(perform(by_customer.merge('query' => ' "*" ')))).to eq([newer.number, older.number])
    end
  end

  context 'with search syntax, without Elasticsearch' do
    it 'asks for plain words instead of answering that nothing matches' do
      %w[created_at:>now-1d title:printer].each do |query|
        expect(perform({ 'query' => query }).content).to eq({ error: 'invalid_arguments', message: described_class::NO_SYNTAX_TEXT }), query
      end
    end

    it 'searches a colon in a sentence, a time or a link as words' do
      ['printer: offline', 'meeting at 10:30', 'https://portal.example.com'].each do |query|
        expect(perform({ 'query' => query })).to have_attributes(status: 'ok'), query
      end
    end
  end

  context 'with words' do
    it 'lists only the matching tickets of the customer' do
      expect(numbers(perform(by_customer.merge('query' => 'printer')))).to eq([older.number])
    end

    it 'names the words in its first line' do
      expect(perform(by_customer.merge('query' => '"printer"')).text).to start_with('Tickets matching "printer" · customer Anna Example (anna@example.com):')
    end
  end

  context 'with each filter' do
    let(:bob)   { create(:customer, firstname: 'Bob', lastname: 'Builder', email: 'bob@example.com', organization:) }
    let(:max)   { create(:customer, firstname: 'Max', lastname: 'Example', email: 'max@other.example', organization: create(:organization, name: 'Other GmbH')) }
    let(:sales) { create(:group, name: 'Sales') }
    let(:agent) { create(:agent, firstname: 'Nina', lastname: 'Agent', groups: [group, sales]) }

    let!(:bobs) { other_ticket('VPN access', 'Please give our new colleague VPN access.', customer: bob, state: Ticket::State.lookup(name: 'pending close'), created_at: 4.days.ago) }
    let!(:maxs)         { other_ticket('CalDAV sync error', 'CalDAV fails since the update.', customer: max, owner: agent, state: Ticket::State.lookup(name: 'pending reminder'), created_at: 5.days.ago) }
    let!(:sales_ticket) { other_ticket('Quote for 20 seats', 'Please send a quote.', customer: max, group: sales, priority: Ticket::Priority.lookup(name: '3 high'), created_at: 6.days.ago) }

    before { older.update!(state: Ticket::State.lookup(name: 'closed')) }

    it 'lists the tickets each filter finds' do
      {
        { 'customer' => 'Bob Builder' }                      => [bobs],
        { 'organization' => 'Example Corp' }                 => [newer, older, bobs],
        { 'organization' => "ID #{organization.id}" }        => [newer, older, bobs],
        { 'customer' => "ID #{bob.id}" }                     => [bobs],
        { 'state_type_category' => 'open' }                  => [newer, bobs, maxs, sales_ticket, another_customers],
        { 'state_type_category' => 'closed' }                => [older],
        { 'state' => ['pending reminder', 'pending close'] } => [bobs, maxs],
        { 'owner' => 'me' }                                  => [maxs],
        { 'owner' => 'nobody' }                              => [newer, older, bobs, sales_ticket, another_customers],
        { 'owner' => 'Nina Agent' }                          => [maxs],
        { 'group' => 'Sales' }                               => [sales_ticket],
        { 'priority' => 'high' }                             => [sales_ticket],
      }.each do |arguments, expected|
        expect(numbers(perform(arguments))).to eq(expected.map(&:number)), arguments.inspect
      end
    end

    it 'lists the tickets of an owner who left' do
      former = create(:agent, firstname: 'Olga', lastname: 'Former', email: 'olga.former@example.com', groups: [group])
      older.update!(owner: former)
      former.update!(active: false)

      expect(numbers(perform({ 'owner' => 'olga.former@example.com' }))).to eq([older.number])
    end

    it 'lists the tickets that match all filters together' do
      result = perform({ 'organization' => 'Example Corp', 'state_type_category' => 'open' })

      expect(numbers(result)).to eq([newer.number, bobs.number])
      expect(result.text).to start_with('Tickets · organization Example Corp · state category open:')
    end

    it 'answers an ambiguous or unknown filter with the candidates or the valid values' do
      expect(perform({ 'organization' => 'Exmaple Corp' }).content).to eq(error: 'invalid_value', message: 'organization "Exmaple Corp" matches no organization. The closest: Example Corp.')
      expect(perform({ 'customer' => 'Example' }).content).to include(error: 'ambiguous', message: include('Anna Example (anna@example.com)', 'Max Example (max@other.example)'))
    end

    it 'finds no ticket for filters that exclude each other, without a search' do
      allow(Ticket).to receive(:search).and_call_original

      result = perform({ 'state_type_category' => 'open', 'state' => ['closed'] })

      expect(Ticket).not_to have_received(:search)
      expect(result.text).to eq('Tickets · state category open · state closed: none.')
    end
  end

  context 'when the conversation\'s ticket does not match' do
    it 'does not name it' do
      result = perform(by_customer.merge('query' => 'printer'))

      expect(result.content).not_to have_key(:conversation_ticket_matches)
      expect(result.text).not_to include('The ticket of this conversation')
    end
  end

  context 'without a ticket in the conversation' do
    it 'searches all the same' do
      result = perform(by_customer, context_object: nil)

      expect(numbers(result)).to eq([ticket.number, newer.number, older.number])
      expect(result.text).not_to include('The ticket of this conversation')
    end
  end

  it 'leaves the start of the first message out unless asked for, as MCP servers keep their rows short' do
    token = create(:token, user: agent, preferences: { permission: %w[ticket.agent] })
    excerpts = lambda do |arguments|
      tool_call = AI::Provider::Completion::ToolCall.new(id: 'call_1', name: 'search_tickets', arguments: by_customer.merge(arguments))
      Service::AI::Tool::Runtime::PerformCall.execute(surface: :mcp, user: agent, tool_call:, token:).content[:tickets].pluck(:excerpt)
    end

    expect(excerpts.call({}).compact).to be_empty
    expect(excerpts.call({ 'response_format' => 'detailed' }).compact.size).to eq(2)
  end

  it 'costs no more queries for a page of many tickets than for one of few' do
    query_count = lambda do
      count    = 0
      callback = ->(*, payload) { count += 1 if !payload[:cached] && payload[:name] != 'SCHEMA' }

      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { perform(by_customer.merge('limit' => 50, 'response_format' => 'detailed')) }
      count
    end

    # The first call fills caches that live longer than a request.
    query_count.call

    expect { 8.times { |index| other_ticket("More #{index}", "Body #{index}.") } }.not_to change(&query_count)
  end

  context 'with more tickets than the limit' do
    it 'pages through them, without counting the conversation\'s ticket or the ones the user may not see' do
      first = perform(by_customer.merge('limit' => 1))

      expect(numbers(first)).to eq([newer.number])
      expect(first.content).to include(has_more: true, next_cursor: be_a(String))
      expect(first.text).to include("More follow: call again with the same arguments and cursor \"#{first.content[:next_cursor]}\".")

      second = perform(by_customer.merge('limit' => 1, 'cursor' => first.content[:next_cursor]))

      expect(numbers(second)).to eq([older.number])
      expect(second.content).to include(has_more: false)
      expect(second.content).not_to have_key(:next_cursor)
      expect(second.content).not_to have_key(:conversation_ticket_matches)
    end

    it 'refuses a cursor it did not give, and one given with another search' do
      cursor = perform(by_customer.merge('limit' => 1)).content[:next_cursor]

      expect(perform(by_customer.merge('cursor' => 'next')).content).to include(error: 'invalid_arguments')
      expect(perform(by_customer.merge('cursor' => '2')).content).to include(error: 'invalid_arguments')
      expect(perform(by_customer.merge('query' => 'outlook', 'cursor' => cursor)).content).to include(
        error: 'invalid_arguments', message: start_with('cursor is no next_cursor of this search. Pass it with the same other arguments'),
      )
    end

    it 'takes its cursor with another page size' do
      cursor = perform(by_customer.merge('limit' => 1)).content[:next_cursor]

      expect(numbers(perform(by_customer.merge('limit' => 5, 'cursor' => cursor)))).to eq([older.number])
    end
  end

  context 'when nothing matches' do
    it 'says so' do
      result = perform({ 'customer' => 'anna@example.com', 'query' => 'invoice' })

      expect(result.content[:tickets]).to be_empty
      expect(result.text).to eq('Tickets matching "invoice" · customer Anna Example (anna@example.com): none.')
    end
  end

  context 'when only the conversation\'s ticket matches' do
    before { create(:ticket_article, :inbound_email, ticket:, body: 'My calendar stopped syncing.', content_type: 'text/plain') }

    it 'says that it does, not that nothing matches' do
      result = perform({ 'customer' => 'anna@example.com', 'query' => 'calendar' })

      expect(result.content).to include(tickets: [], conversation_ticket_matches: true)
      expect(result.text).to eq(
        "Tickets matching \"calendar\" · customer Anna Example (anna@example.com): only the ticket of this conversation, #{ticket.number}, " \
        'matches. Its facts are in the context, and get_ticket reads it.'
      )
    end
  end

  context 'when the conversation\'s ticket matches beyond the first page' do
    let(:ticket) { create(:ticket, group:, customer:, title: 'Calendar does not sync', created_at: 5.days.ago) }

    it 'says so on the first page' do
      result = perform(by_customer.merge('limit' => 1))

      expect(numbers(result)).to eq([newer.number])
      expect(result.content).to include(conversation_ticket_matches: true)
      expect(result.text).to include("The ticket of this conversation, #{ticket.number}, matches as well.")
    end
  end

  it 'keeps a line break in a filter\'s name from starting a line of its own' do
    customer.update_columns(lastname: "Example\u2028Ticket 1 (ID 1) · closed")

    expect(perform(by_customer).text.lines.first).to eq("Tickets · customer Anna Example Ticket 1 (ID 1) · closed (anna@example.com):\n")
  end

  context 'when an MCP client searches' do
    let(:token) { create(:token, user: agent, preferences: { permission: %w[ticket.agent] }) }

    def call(arguments)
      Service::MCPServer::CallTool.execute(tool: described_class, arguments:, user: agent, token:).to_h
    end

    before do
      Setting.set('http_type', 'https')
      Setting.set('fqdn', 'support.example.com')
    end

    it 'is offered to an agent\'s token' do
      expect(Service::AI::Tool::Runtime::Router.offered_tools(user: agent, surface: :mcp, token:)).to include(described_class)
    end

    it 'lists every match with its link, fitting its output schema, without a conversation' do
      result  = call(by_customer)
      content = result[:structuredContent]

      expect(content['tickets'].pluck('number')).to eq([ticket.number, newer.number, older.number])
      expect(content['tickets'].first).to include(
        'url'      => "https://support.example.com/#ticket/zoom/#{ticket.id}",
        'customer' => include('url' => "https://support.example.com/#user/profile/#{customer.id}"),
      )
      expect(content).not_to have_key('conversation_ticket_matches')
      expect(result.dig(:content, 0, :text)).to include("Ticket #{newer.number} (ID #{newer.id}): https://support.example.com/#ticket/zoom/#{newer.id}")
      expect(result.dig(:content, 0, :text)).not_to match(%r{conversation}i)
      expect(output_schema_errors(described_class.tool_output_schema, content)).to be_empty
    end

    it 'pages through the matches to the end, ten at a time' do
      12.times { |index| other_ticket("Question #{index}", 'A question.', created_at: (index + 4).days.ago) }

      first  = call(by_customer.merge(limit: 10))[:structuredContent]
      second = call(by_customer.merge(limit: 10, cursor: first['next_cursor']))[:structuredContent]

      expect(first).to include('has_more' => true)
      expect(first['tickets'].size).to eq(10)
      expect(second).to include('has_more' => false)
      expect(second['tickets'].size).to eq(5)
      expect((first['tickets'] + second['tickets']).pluck('id').uniq.size).to eq(15)
    end

    it 'lists the newest tickets the user may see for what asks for everything' do
      [{}, { query: '' }, { query: '*' }, { query: '**' }, { query: '?' }, { query: '%' }, { query: '_' }, { query: '"" OR ""' }, { customer: ' ', query: ' ' }].each do |arguments|
        result = call(arguments)

        expect(result).not_to include(isError: true), arguments.inspect
        expect(result[:structuredContent]['tickets'].pluck('number')).to eq([ticket, newer, older, another_customers].map(&:number)), arguments.inspect
      end
    end
  end

  context 'with Elasticsearch', searchindex: true do
    # The word in every ticket the search must leave out, too: the conversation's own, another group's and another
    #   customer's.
    let!(:another_customers_password) do
      create(:ticket, group:, title: 'Password of another customer').tap do |other|
        create(:ticket_article, :inbound_email, ticket: other, body: 'My password expired.', content_type: 'text/plain')
      end
    end

    before do
      create(:ticket_article, :inbound_email, ticket:, body: 'I forgot my password.', content_type: 'text/plain')
      other_ticket('Payroll password', 'The payroll tool asks for my password.', group: create(:group))
      searchindex_model_reload([Ticket])
    end

    it 'sorts the words found in the order asked for, also by order_by alone, and pages in it' do
      vpn = other_ticket('VPN password', 'The VPN rejects my password.', created_at: 2.days.ago)
      searchindex_model_reload([Ticket])

      first = perform(by_customer.merge('query' => 'password', 'order_by' => 'asc', 'limit' => 1))
      last  = perform(by_customer.merge('query' => 'password', 'order_by' => 'asc', 'limit' => 1, 'cursor' => first.content[:next_cursor]))

      expect([first, last].flat_map { |page| numbers(page) }).to eq([vpn.number, newer.number])
      expect(numbers(perform(by_customer.merge('query' => 'password', 'sort_by' => 'created_at')))).to eq([newer.number, vpn.number])
    end

    it "finds the words only in the customer's tickets the user may see, and counts no other" do
      result = perform(by_customer.merge('query' => 'password', 'limit' => 1))

      expect(numbers(result)).to eq([newer.number])
      expect(result.content).to include(has_more: false, conversation_ticket_matches: true)
    end

    it 'lists the newest tickets the user may see without words' do
      [{}, { 'query' => '*' }, { 'query' => '?' }].each do |arguments|
        expect(numbers(perform(arguments))).to eq([another_customers_password, newer, older, another_customers].map(&:number)), arguments.inspect
      end
    end

    it 'takes Lucene query syntax, as the search box does, within what the user may see' do
      older.tag_add('vip', 1)
      searchindex_model_reload([Ticket])

      {
        'title:printer'            => [older],
        'created_at:>now-36h'      => [another_customers_password, newer],
        '"asks for my password"'   => [newer],
        'title:payroll'            => [],
        'password AND NOT outlook' => [another_customers_password],
        '"OR"'                     => [],
        'tags:vip'                 => [older],
        'article.body:hour'        => [newer],
      }.each do |query, expected|
        result = perform({ 'query' => query })

        expect(result).to have_attributes(status: 'ok'), query
        expect(numbers(result)).to eq(expected.map(&:number)), query
      end
    end

    it 'answers a query Elasticsearch cannot run as a failed search, not as one without matches' do
      result = perform({ 'query' => 'title:(printer' })

      expect(result.content).to eq(error: 'search_failed', message: described_class::FAILED_TEXT)
    end

    it 'finds the words by every filter' do
      newer.update!(priority: Ticket::Priority.lookup(name: '3 high'), owner: agent, state: Ticket::State.lookup(name: 'pending reminder'))
      searchindex_model_reload([Ticket])

      {
        { 'organization' => 'Example Corp' } => [newer],
        { 'state_type_category' => 'open' }  => [another_customers_password, newer],
        { 'state' => ['pending reminder'] }  => [newer],
        { 'owner' => 'me' }                  => [newer],
        { 'group' => 'Support' }             => [another_customers_password, newer],
        { 'priority' => '3 high' }           => [newer],
      }.each do |filter, expected|
        expect(numbers(perform(filter.merge('query' => 'password')))).to eq(expected.map(&:number)), filter.inspect
      end
    end

    context 'when the index has not caught up with ticket changes' do
      it 'omits a ticket moved to a group the user may not read' do
        newer.update!(group: create(:group), title: 'Payroll question')

        result = perform(by_customer.merge('query' => 'password'))

        expect(result).to have_attributes(status: 'ok')
        expect(result.content[:tickets]).to be_empty
        expect(result.content).to include(has_more: false)
        expect(result.content).not_to have_key(:next_cursor)
        expect(result.text).not_to include(newer.number, newer.title, newer.articles.first.body)
      end

      it 'omits a ticket whose filtered fields changed' do
        filters = { 'query' => 'password', 'customer' => 'anna@example.com', 'organization' => 'Example Corp', 'state_type_category' => 'open', 'owner' => 'nobody', 'group' => 'Support', 'priority' => '2 normal' }
        agent.update!(groups: [group, create(:group, name: 'Sales')])

        expect(numbers(perform(filters))).to eq([newer.number])

        {
          customer_id:     create(:customer).id,
          organization_id: create(:organization).id,
          state_id:        Ticket::State.lookup(name: 'closed').id,
          owner_id:        create(:agent, groups: [group]).id,
          priority_id:     Ticket::Priority.lookup(name: '1 low').id,
          group_id:        Group.find_by(name: 'Sales').id,
        }.each do |column, value|
          original = newer.reload[column]

          # Without callbacks, so that the index keeps the old value.
          newer.update_columns(column => value)
          expect(numbers(perform(filters))).to be_empty, column.inspect
          newer.update_columns(column => original)
        end
      end

      context 'with several pages of matches' do
        let!(:oldest) { other_ticket('Password reset', 'My password needs resetting.', created_at: 5.days.ago) }

        before do
          older.update!(title: 'Printer password')
          searchindex_model_reload([Ticket])
        end

        it 'fills a page past stale hits and keeps the next visible ticket for the next page' do
          newer.update!(group: create(:group))

          first = perform(by_customer.merge('query' => 'password', 'limit' => 1))
          second = perform(by_customer.merge('query' => 'password', 'limit' => 1, 'cursor' => first.content[:next_cursor]))

          expect(numbers(first)).to eq([older.number])
          expect(first.content).to include(has_more: true)
          expect(numbers(second)).to eq([oldest.number])
          expect(second.content).to include(has_more: false)
          expect(second.content).not_to have_key(:next_cursor)
        end

        it 'continues past a full batch of stale hits' do
          newer.update!(group: create(:group))
          older.update!(customer: create(:customer))

          result = perform(by_customer.merge('query' => 'password', 'limit' => 1))

          expect(numbers(result)).to eq([oldest.number])
          expect(result.content).to include(has_more: false)
          expect(result.content).not_to have_key(:next_cursor)
        end

        it 'counts no further results when the remaining hits are no longer readable' do
          older.update!(group: create(:group))
          oldest.update!(customer: create(:customer))

          result = perform(by_customer.merge('query' => 'password', 'limit' => 1))

          expect(numbers(result)).to eq([newer.number])
          expect(result.content).to include(has_more: false)
          expect(result.content).not_to have_key(:next_cursor)
          expect(result.text).to include('No more follow.')
        end
      end
    end
  end
end
