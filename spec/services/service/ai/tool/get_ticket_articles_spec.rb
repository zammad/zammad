# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'services/service/ai/tool/loads_context_object_examples'

RSpec.describe Service::AI::Tool::GetTicketArticles, :aggregate_failures do
  let(:group)    { create(:group) }
  let(:agent)    { create(:agent, firstname: 'Nina', lastname: 'Agent', groups: [group]) }
  let(:customer) { create(:customer, firstname: 'Anna', lastname: 'Example') }
  let(:ticket)   { create(:ticket, group:, customer:, title: 'Outlook sync fails after update') }

  # 30 messages the agent sees — the customer's first one, then the agent and the customer in turn, an internal note as
  #   the fifth — and a system notification between them, which no position counts.
  let!(:articles) do
    (1..30).map do |position|
      if position == 4
        create(:ticket_article, ticket:, sender_name: 'System', type_name: 'email', internal: true, body: 'Notification.',
                                preferences: { 'perform_origin' => 'trigger', 'notification' => true })
      end

      trait = if position == 5 then :internal_note
              elsif position.odd? then :inbound_email
              else :outbound_email
              end
      create(:ticket_article, trait, ticket:, body: "Message #{position}: #{'word ' * (position == 12 ? 2_000 : 3)}end", content_type: 'text/plain',
                                     created_by_id: (position.odd? && position != 5 ? customer : agent).id)
    end
  end

  def perform(arguments = {}, context_object: Gql::ZammadSchema.id_from_object(ticket))
    tool_call = AI::Provider::Completion::ToolCall.new(id: 'call_1', name: 'get_ticket_articles', arguments:)

    Service::AI::Tool::Runtime::PerformCall.execute(surface: :harness, user: agent, tool_call:, audience: AI::Harness::Audience::HUMAN_AGENTS, context_object:)
  end

  def positions(result)
    result.content[:messages].pluck(:position)
  end

  def cursor_at(offset)
    Service::AI::Tool::Runtime::Cursor.encode(offset:, scope: { ticket: ticket.id })
  end

  it 'is offered to an agent in the harness' do
    expect(Service::AI::Tool::Runtime::Router.offered_tools(surface: :harness, user: agent, audience: AI::Harness::Audience::HUMAN_AGENTS)).to include(described_class)
  end

  it 'says over MCP that files are counted in the index and listed with their IDs for read_attachment, as the harness prompt says it in the chat' do
    expect(described_class.description_for(:mcp)).to include('The index says how many files a message has; with positions, its files are listed with their IDs, by which read_attachment reads them')
    expect(described_class.description_for(:harness)).not_to include('attachments')
  end

  describe 'the index' do
    it 'lists the first page, each message with the start of its text, without the system notification' do
      result = perform

      expect(result).to have_attributes(status: 'ok')
      expect(result.content).to include(message_count: 30, has_more: true, next_cursor: cursor_at(20))
      expect(positions(result)).to eq((1..20).to_a)
      expect(result.content[:messages].first).to include(id: articles.first.id, position: 1, sender: 'Customer', from: 'Anna Example', internal: false, text: 'Message 1: word word word end')
      expect(result.content[:messages].first).not_to have_key(:subject)
      expect(result.content[:messages].fifth).to include(position: 5, internal: true)
      expect(result.text).not_to include('Notification.')
    end

    it 'says how many files each listed message has, and lists them with their IDs where a message is read with its text' do
      files = Array.new(2) { |index| create(:store, object: 'Ticket::Article', o_id: articles.third.id, filename: "sync-#{index}.log") }

      index = perform.content[:messages].find { |message| message[:position] == 3 }
      full  = perform({ 'positions' => [3] })

      expect(index).to include(attachment_count: 2).and not_include(:attachments)
      expect(perform.text).to include('message="3" type="email" from="Anna Example" time=').and include('files="2">')
      expect(full.content[:messages].first[:attachments]).to match(files.map { |file| include(id: file.id, filename: file.filename) })
      expect(full.text).to include("attachments=\"sync-0.log (id #{files.first.id}), sync-1.log (id #{files.second.id})\"")
    end

    it 'cuts each text at its start' do
      long = perform.content[:messages].find { |message| message[:position] == 12 }

      expect(long).to include(truncated: true, full_length: be > 10_000)
      expect(long[:text].length).to be <= described_class::EXCERPT_LENGTH
    end

    it 'gives the model the count, each message marked with its writer, and the way on' do
      text = perform.text

      expect(text).to start_with("Ticket #{ticket.number} has 30 messages; the index of 1 to 20 below shows the start of each.")
      expect(text).to include('<text source="customer" message="1" type="email" from="Anna Example"', 'visibility="internal"')
      expect(text).to end_with("More follow: call again with the same arguments and cursor \"#{cursor_at(20)}\". Call again with positions to read messages with their text.")
    end

    it 'goes on from the cursor to the last message' do
      result = perform({ 'cursor' => cursor_at(20) })

      expect(positions(result)).to eq((21..30).to_a)
      expect(result.content).to include(has_more: false)
      expect(result.content).not_to have_key(:next_cursor)
      expect(result.text).to include('No more follow.')
    end

    it 'takes a smaller page' do
      expect(positions(perform({ 'limit' => 5 }))).to eq((1..5).to_a)
    end

    it 'refuses a cursor it did not give, one beyond the messages and one of another ticket\'s index' do
      other = Service::AI::Tool::Runtime::Cursor.encode(offset: 20, scope: { ticket: create(:ticket).id })

      ['next', '20', '0x10', cursor_at(30), cursor_at(99), cursor_at(-1), other].each do |cursor|
        expect(perform({ 'cursor' => cursor }).content).to include(error: 'invalid_arguments'), cursor
      end
    end

    it 'costs as many queries for a large page as for a small one' do
      queries = lambda do |limit|
        count    = 0
        callback = ->(*, payload) { count += 1 if payload[:sql].match?(%r{\A\s*SELECT}i) && !payload[:cached] }
        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { perform({ 'limit' => limit }) }
        count
      end

      expect(queries.call(25)).to eq(queries.call(5))
    end
  end

  describe 'messages with their text' do
    it 'reads the chosen messages with their subject, in order' do
      result = perform({ 'positions' => [21, 3] })

      expect(positions(result)).to eq([3, 21])
      expect(result.content[:messages].first).to include(id: articles[2].id, subject: articles[2].subject, truncated: false)
      expect(result.text).to start_with("Ticket #{ticket.number} has 30 messages; shown below with their text: 3, 21.")
      expect(result.content).not_to have_key(:has_more)
    end

    it 'reads a long message whole when it is asked for alone' do
      message = perform({ 'positions' => [12] }).content[:messages].sole

      expect(message).to include(truncated: false)
      expect(message[:text]).to end_with('word end')
    end

    context 'with fewer characters than the chosen messages need' do
      before do
        stub_const("#{described_class}::TEXT_BUDGET", 3_000)
        articles[13].update!(body: "Message 14: #{'word ' * 2_000}end")
      end

      it 'shares them, a short message leaving its rest to the long ones, and says how to read a cut one whole' do
        result   = perform({ 'positions' => [3, 12, 14] })
        messages = result.content[:messages].index_by { |message| message[:position] }

        expect(messages[3]).to include(truncated: false)
        expect(messages.values_at(12, 14)).to all(include(truncated: true, text: satisfy { |text| text.length.between?(1_400, 1_500) }))
        expect(result.text).to include('Cut as the messages share 3,000 characters: 12, 14. Call again with one of these positions alone, which gives it all 3,000 characters.')
      end

      it 'cuts a message longer than all of them, and says so' do
        result = perform({ 'positions' => [12] })

        expect(result.content[:messages].sole).to include(truncated: true, text: satisfy { |text| text.length <= 3_000 })
        expect(result.text).to include('characters shown')
        expect(result.text).not_to include('Call again with one of these positions alone')
      end
    end

    it 'numbers the messages as get_ticket does, past the system notification' do
      expect(perform({ 'positions' => [4] }).content[:messages].sole).to include(id: articles[3].id, text: start_with('Message 4:'))
    end

    it 'refuses a position outside the ticket, naming the range' do
      expect(perform({ 'positions' => [31] }).content).to eq(error: 'invalid_arguments', message: 'Pass one to 5 positions between 1 and 30, the messages of this ticket.')
    end

    it 'refuses more positions than it reads at once' do
      expect(perform({ 'positions' => [1, 2, 3, 4, 5, 6] }).content).to include(error: 'invalid_arguments')
    end
  end

  describe 'quotes and signatures' do
    before do
      articles[12].update!(body: "Message 13: please call me.\n\nOn Monday, Nina Agent wrote:\n> Which number?\n\n-- \nAnna Example\nPhone +49 30 1234567")
      articles[0].update!(body: "Message 1: my calendar does not sync.\n\n> Forwarded from the help page")
    end

    it 'leaves them out of a reply by default, says how to keep them, and keeps them in the first message' do
      result = perform({ 'positions' => [1, 13] })

      expect(result.content[:messages].first[:text]).to include('Forwarded from the help page')
      expect(result.content[:messages].second[:text]).to eq('Message 13: please call me.')
      expect(result.text).not_to include('Which number?', '+49 30 1234567')
      expect(result.text).to end_with('Quotes and signatures of replies are left out: call again with response_format "detailed" to keep them.')
    end

    it 'keeps them with response_format "detailed"' do
      result = perform({ 'positions' => [13], 'response_format' => 'detailed' })

      expect(result.content[:messages].sole[:text]).to include('> Which number?', 'Phone +49 30 1234567')
      expect(result.text).to include('│ Phone +49 30 1234567')
      expect(result.text).not_to include('Quotes and signatures of replies are left out')
    end

    it 'applies the choice to the index excerpts' do
      excerpt = ->(arguments) { perform({ 'cursor' => cursor_at(10), 'limit' => 5 }.merge(arguments)).content[:messages].find { |message| message[:position] == 13 }[:text] }

      expect(excerpt.call({})).to eq('Message 13: please call me.')
      expect(excerpt.call({ 'response_format' => 'detailed' })).to include('Which number?', 'Phone +49 30 1234567')
    end
  end

  describe 'searching the messages' do
    # 60 messages; the error code in the customer's report, deep in a long one, quoted in a reply, in a signature and in
    #   an internal note, as a part of a longer name, and in a system notification, which no search finds.
    let(:bodies) do
      {
        7  => 'The sync stops with SRM_FAILURE since yesterday.',
        12 => "#{'Context of the log. ' * 30}Then SRM_FAILURE again on door-03.example.org.",
        23 => "We are looking into it.\n\nOn Monday, Anna Example wrote:\n> The sync stops with SRM_FAILURE since yesterday.",
        35 => "Please call back.\n\n-- \nAnna Example\nError seen: SRM_FAILURE",
        41 => 'Checked door-03.example.org: SRM_FAILURE in the service log.',
        50 => 'door-03 is back, but the srm_failure-handler restarted.',
        55 => 'Fehler beim Abgleich für Kunde Müller, node--backup läuft wieder.',
      }
    end

    let!(:articles) do
      (1..60).map do |position|
        if position == 30
          create(:ticket_article, ticket:, sender_name: 'System', type_name: 'email', internal: true, body: 'Notification: SRM_FAILURE',
                                  preferences: { 'perform_origin' => 'trigger', 'notification' => true })
        end

        trait = if position == 41 then :internal_note
                elsif position.odd? then :inbound_email
                else :outbound_email
                end
        create(:ticket_article, trait, ticket:, body: bodies.fetch(position, "Message #{position}."), content_type: 'text/plain')
      end
    end

    def search_cursor_at(offset, *words)
      Service::AI::Tool::Runtime::Cursor.encode(offset:, scope: { ticket: ticket.id, query: words.map(&:downcase) })
    end

    it 'lists only the messages that hold the word, in their positions, also in a quote, a signature and an internal note' do
      result = perform({ 'query' => 'srm_failure' })

      expect(result).to have_attributes(status: 'ok')
      expect(result.content).to include(message_count: 60, found_count: 5, query: ['srm_failure'], has_more: false)
      expect(positions(result)).to eq([7, 12, 23, 35, 41])
      expect(result.text).to include('Ticket', 'has 60 messages; 5 of them hold all of "srm_failure"', 'Call again with positions to read messages with their text.')
    end

    it 'finds a message only where it holds every word, each as a whole word' do
      expect(positions(perform({ 'query' => 'SRM_FAILURE door-03.example.org' }))).to eq([12, 41])
      expect(positions(perform({ 'query' => '"door-03"' }))).to eq([50])
      expect(positions(perform({ 'query' => 'backup' }))).to eq([])
      expect(positions(perform({ 'query' => 'node--backup für' }))).to eq([55])
    end

    it 'shows the passage around the first match of a long message instead of its start' do
      row = perform({ 'query' => 'SRM_FAILURE' }).content[:messages].find { |message| message[:position] == 12 }

      expect(row).to include(truncated: true, full_length: 646, text: start_with('of the log.').and(end_with('Then SRM_FAILURE again on door-03.example.org.')))
      expect(row[:text].length).to be < 200
    end

    it 'keeps a long match in the passage, also where no space follows it soon' do
      host = "#{'segment-of-a-long-host-name.' * 4}example-subsidiary.example.org"
      expect(host.length).to be > 120
      articles[5].update!(body: "#{'Context of the log. ' * 30}Then the gateway #{host} refused it.")
      articles[6].update!(body: "#{'Context of the log. ' * 30}See https://#{host}/status/#{'x' * 60} for it.")

      rows = perform({ 'query' => host }).content[:messages]

      expect(rows.pluck(:position)).to eq([6, 7])
      expect(rows.pluck(:text)).to all(include(host))
    end

    it 'keeps the match in a long link without a space after it, deep in a message and near its start' do
      articles[5].update!(body: "#{'Context of the log. ' * 30}See https://door-03.example.org/status/#{'x' * 300} for it.")
      articles[6].update!(body: "See https://door-03.example.org/status/#{'x' * 300} for it. #{'More of the log. ' * 30}")

      rows = perform({ 'query' => 'door-03.example.org' }).content[:messages].select { |row| row[:position].in?(6..7) }

      expect(rows.pluck(:text)).to all(include('door-03.example.org').and(end_with(' …')))
      expect(rows.pluck(:text).map(&:length)).to all(be <= 200)
    end

    it 'pages the found messages, and refuses the cursor of the plain index' do
      first = perform({ 'query' => 'SRM_FAILURE', 'limit' => 2 })

      expect(positions(first)).to eq([7, 12])
      expect(first.content).to include(has_more: true, next_cursor: search_cursor_at(2, 'SRM_FAILURE'))
      expect(positions(perform({ 'query' => 'SRM_FAILURE', 'limit' => 2, 'cursor' => first.content[:next_cursor] }))).to eq([23, 35])
      expect(perform({ 'query' => 'SRM_FAILURE', 'cursor' => cursor_at(2) }).content).to include(error: 'invalid_arguments')
      expect(perform({ 'query' => 'ORA-12541', 'cursor' => search_cursor_at(2, 'ORA-12541') }).content).to include(error: 'invalid_arguments')
    end

    it 'costs as many queries for many found messages as for few, however long the ticket' do
      queries = lambda do
        count    = 0
        callback = ->(*, payload) { count += 1 if payload[:sql].match?(%r{\A\s*SELECT}i) && !payload[:cached] }
        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { perform({ 'query' => 'SRM_FAILURE', 'limit' => 50 }) }
        count
      end

      # The first call fills the lookup caches, which no later call reads again.
      queries.call
      few = queries.call
      create_list(:ticket_article, 20, :outbound_email, ticket:, body: 'SRM_FAILURE again.', content_type: 'text/plain')

      expect(queries.call).to eq(few)
    end

    it 'says how to keep the quotes and signatures a match may stand in' do
      expect(perform({ 'query' => 'SRM_FAILURE' }).text).to end_with('Add response_format "detailed" to keep the quotes and signatures a match may stand in.')
      expect(perform({ 'query' => 'SRM_FAILURE', 'response_format' => 'detailed' }).text).not_to include('Add response_format')
    end

    it 'says which words it searched in how many messages where none holds them' do
      result = perform({ 'query' => 'ORA-12541' })

      expect(result).to have_attributes(status: 'ok')
      expect(result.content).to include(message_count: 60, found_count: 0, query: ['ORA-12541'], messages: [])
      expect(result.text).to include('has 60 messages; none of them holds all of "ORA-12541"')
    end

    it 'refuses a query without words' do
      expect(perform({ 'query' => ' "" * ' }).content).to eq(error: 'invalid_arguments', message: 'Pass one to 10 words as query.')
    end

    it 'reads positions with their text, whatever the query' do
      expect(positions(perform({ 'query' => 'SRM_FAILURE', 'positions' => [2] }))).to eq([2])
    end
  end

  it_behaves_like 'an AI tool loading its object' do
    let(:tool)              { described_class }
    let(:user)              { agent }
    let(:readable_object)   { ticket }
    let(:unreadable_object) { create(:ticket) }
  end

  context 'when an MCP client reads it' do
    let(:token) { create(:token, user: agent, preferences: { permission: %w[ticket.agent] }) }

    def call(arguments)
      Service::MCPServer::CallTool.execute(tool: described_class, arguments:, user: agent, token:).to_h
    end

    it 'is offered to an agent\'s token' do
      expect(Service::AI::Tool::Runtime::Router.offered_tools(user: agent, surface: :mcp, token:)).to include(described_class)
    end

    it 'returns an index and chosen messages that fit its output schema, with the ticket\'s link' do
      [{}, { cursor: cursor_at(20) }, { positions: [12, 5] }, { query: 'word' }].each do |arguments|
        result = call({ ticket_number: ticket.number, **arguments })
        errors = output_schema_errors(described_class.tool_output_schema, result[:structuredContent])

        expect(errors).to be_empty, "#{arguments}: #{errors.first(3).join(' | ')}"
        expect(result[:structuredContent]['ticket']).to include('type' => 'Ticket', 'id' => ticket.id, 'url' => end_with("#ticket/zoom/#{ticket.id}"))
      end
    end

    it_behaves_like 'an AI tool loading a named ticket' do
      let(:tool)              { described_class }
      let(:user)              { agent }
      let(:readable_object)   { ticket }
      let(:unreadable_object) { create(:ticket) }
    end
  end
end
