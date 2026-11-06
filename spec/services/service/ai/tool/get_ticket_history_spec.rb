# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'services/service/ai/tool/loads_context_object_examples'

RSpec.describe Service::AI::Tool::GetTicketHistory, :aggregate_failures do
  let(:group)    { create(:group) }
  let(:agent)    { create(:agent, firstname: 'Nina', lastname: 'Agent', groups: [group]) }
  let(:customer) { create(:customer, firstname: 'Anna', lastname: 'Example') }
  let(:ticket)   { travel_to(3.days.ago) { create(:ticket, group:, customer:, title: 'Outlook sync fails after update') } }

  def perform(arguments = {}, context_object: Gql::ZammadSchema.id_from_object(ticket))
    tool_call = AI::Provider::Completion::ToolCall.new(id: 'call_1', name: 'get_ticket_history', arguments:)

    Service::AI::Tool::Runtime::PerformCall.execute(surface: :harness, user: agent, tool_call:, audience: AI::Harness::Audience::HUMAN_AGENTS, context_object:)
  end

  def add_history(time:, author: agent, **data)
    History.add(history_object: 'Ticket', o_id: ticket.id, created_by_id: author.id, created_at: time, **data)
  end

  def descriptions(result)
    result.content[:changes].flat_map { |change| change[:entries].pluck(:description) }
  end

  it 'is offered to an agent in the harness, not always loaded' do
    expect(Service::AI::Tool::Runtime::Router.offered_tools(surface: :harness, user: agent, audience: AI::Harness::Audience::HUMAN_AGENTS)).to include(described_class)
    expect(described_class.always_loaded?).to be(false)
  end

  describe 'the entries' do
    before do
      ticket
      add_history(time: 2.days.ago, history_type: 'updated', history_attribute: 'group', value_from: 'Users', value_to: '2nd Level', id_from: 1, id_to: 2)
      add_history(time: 1.day.ago, history_type: 'updated', history_attribute: 'priority', value_from: '2 normal', value_to: '3 high', id_from: 2, id_to: 3)
    end

    it 'lists them newest first, with who, when, the field and its old and new value in words' do
      result = perform
      latest = result.content[:changes].first

      expect(latest).to include(time: Service::AI::Tool::Output.time(1.day.ago), issuer: { type: 'User', id: agent.id, name: 'Nina Agent' })
      expect(latest[:entries]).to eq([{ action: 'updated', description: 'Priority: 2 normal → 3 high', field: 'Priority', field_key: 'priority_id', from: '2 normal', to: '3 high' }])
      expect(descriptions(result).first(2)).to eq(['Priority: 2 normal → 3 high', 'Group: Users → 2nd Level'])
      expect(descriptions(result)).to include('created the ticket')
    end

    it 'names an option by its label, also one removed since' do
      attribute = ObjectManager::Attribute.get(object: 'Ticket', name: 'type')
      attribute.data_option[:options] = { 'incident' => 'Incident' }
      attribute.data_option[:historical_options] = { 'problem' => 'Problem', 'incident' => 'Incident' }
      attribute.save!(validate: false)
      add_history(time: 1.hour.ago, history_type: 'updated', history_attribute: 'type', value_from: 'problem', value_to: 'incident')

      expect(perform.content[:changes].first[:entries].first).to include(field: attribute.display, from: 'Problem', to: 'Incident')
    end

    it 'decodes multi-select history before resolving current and removed labels' do
      attribute = ObjectManager::Attribute.get(object: 'Ticket', name: 'type')
      attribute.data_type = 'multiselect'
      attribute.data_option[:options] = { 'incident' => 'Incident' }
      attribute.data_option[:historical_options] = { 'problem' => 'Problem' }
      attribute.save!(validate: false)
      values = ticket.history_attribute_changes('type', [%w[problem], %w[problem incident]])
      add_history(time: 1.hour.ago, history_type: 'updated', history_attribute: 'type', **values)

      expect(perform.content[:changes].first[:entries].first).to include(field_key: 'type', from: 'Problem', to: 'Problem, Incident')
      expect(perform.text).to include('Problem → Problem, Incident')
    end

    it 'preserves malformed or truncated multi-select history without raising' do
      attribute = ObjectManager::Attribute.get(object: 'Ticket', name: 'type')
      attribute.data_type = 'multiselect'
      attribute.save!(validate: false)
      ['["incident",', '{"incident": true}', '[null]', '[]'].each_with_index do |stored, index|
        add_history(time: (index + 1).hours.ago, history_type: 'updated', history_attribute: 'type', value_to: stored)
      end

      expect(perform.content[:changes].first(4).map { |change| change[:entries].first[:to] }).to eq(['["incident",', '{"incident": true}', '[null]', nil])
    end

    it 'preserves date-shaped titles and relation names literally' do
      stamp = '2026-11-02T08:15:03Z'
      add_history(time: 2.hours.ago, history_type: 'updated', history_attribute: 'title', value_to: stamp)
      add_history(time: 1.hour.ago, history_type: 'updated', history_attribute: 'group', value_to: stamp)

      expect(perform.content[:changes].first(2).map { |change| change[:entries].first[:to] }).to eq([stamp, stamp])
    end

    it 'shows a time in the system\'s time zone, and a text that only starts with one as text' do
      add_history(time: 2.hours.ago, history_type: 'updated', history_attribute: 'pending_time', value_to: '2026-11-04 11:29:00 UTC')
      add_history(time: 1.hour.ago, history_type: 'updated', history_attribute: 'title', value_from: '2026-11-02 08:15:03 CRITICAL: disk full on srv1', value_to: 'Disk full')

      expect(descriptions(perform).first(2)).to eq([
                                                     'Title: 2026-11-02 08:15:03 CRITICAL: disk full on srv1 → Disk full',
                                                     "#{ObjectManager::Attribute.get(object: 'Ticket', name: 'pending_time').display}: - → #{Service::AI::Tool::Output.time(Time.zone.parse('2026-11-04 11:29:00 UTC'))}",
                                                   ])
    end

    it 'reads a change of the checklist without writing anything' do
      History.add(history_object: 'Checklist::Item', history_type: 'updated', history_attribute: 'text', o_id: 96, related_history_object: 'Ticket',
                  related_o_id: ticket.id, value_from: 'Call the customer', value_to: 'Call the customer back', created_by_id: agent.id, created_at: 1.hour.ago)

      expect { perform }.not_to change(ObjectLookup, :count)
      expect(descriptions(perform).first).to eq('checklist item Text: Call the customer → Call the customer back')
    end

    it 'gives the model the history as the ticket\'s text, marked' do
      expect(perform.text).to include("Ticket #{ticket.number} has", '<text source="ticket" field="history">', '│ - Priority: 2 normal → 3 high')
    end

    it 'groups the entries of one issuer and moment' do
      add_history(time: 1.day.ago + 5.seconds, history_type: 'added', history_attribute: 'tag', value_to: 'vip')

      expect(perform.content[:changes].first[:entries].pluck(:description)).to eq(['added tag vip', 'Priority: 2 normal → 3 high'])
    end

    it 'costs no more queries for a page with more field changes' do
      field_changes = lambda do |count, offset|
        count.times do |index|
          add_history(time: (offset + index).hours.ago, history_type: 'updated', history_attribute: 'title', value_from: "Old #{index}", value_to: "New #{index}")
          add_history(time: (offset + index).hours.ago, history_type: 'updated', history_attribute: 'priority', value_from: '2 normal', value_to: '3 high', id_from: 2, id_to: 3)
        end
      end
      queries = lambda do
        count    = 0
        callback = ->(*, payload) { count += 1 if !payload[:cached] && payload[:name] != 'SCHEMA' }
        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { perform }
        count
      end

      field_changes.call(2, 20)
      # The first call fills caches that live longer than a request.
      queries.call

      expect { field_changes.call(8, 40) }.not_to change { queries.call }
    end
  end

  describe 'the sources' do
    let(:trigger) { create(:trigger, name: 'VIP customer') }

    it 'names what made a change instead of a person' do
      {
        trigger                                     => 'Trigger: VIP customer',
        create(:job, name: 'Close stale')           => 'Scheduler: Close stale',
        create(:postmaster_filter, name: 'Billing') => 'Postmaster filter: Billing',
        create(:macro, name: 'Solved')              => 'Macro: Solved',
        create(:ai_agent, name: 'Triage')           => 'AI agent: Triage',
      }.each_with_index do |(source, name), index|
        add_history(time: (index + 1).hours.ago, history_type: 'updated', history_attribute: 'priority', value_from: '1 low', value_to: '2 normal', sourceable: source)

        expect(perform.content[:changes]).to include(include(issuer: include(name:, source: name.split(':').first)))
      end
    end

    it 'names a deleted one by the name the entry kept' do
      add_history(time: 1.hour.ago, history_type: 'updated', history_attribute: 'priority', value_from: '2 normal', value_to: '3 high', sourceable: trigger)
      trigger.destroy!

      expect(perform.content[:changes].first[:issuer]).to eq(name: 'Trigger: VIP customer (deleted)', source: 'Trigger', deleted: true)
    end

    it 'names the system for a change nobody made' do
      add_history(time: 1.hour.ago, author: User.find(1), history_type: 'updated', history_attribute: 'state', value_from: 'new', value_to: 'open')

      expect(perform.content[:changes].first[:issuer]).to eq(name: 'System')
    end

    it 'names the time event a trigger ran for' do
      add_history(time: 1.hour.ago, history_type: 'time_trigger_performed', value_from: 'escalation', sourceable: trigger)

      expect(perform.content[:changes].first).to include(issuer: include(name: 'Trigger: VIP customer'), entries: [{ action: 'time_trigger_performed', description: 'ran because the ticket escalated' }])
    end
  end

  describe 'the kinds of entries' do
    it 'words tags, mentions, the checklist, notifications and sent emails' do
      mentioned = create(:agent, firstname: 'Max', lastname: 'Second')
      ticket
      add_history(time: 6.hours.ago, history_type: 'removed', history_attribute: 'tag', value_to: 'vip')
      History.add(history_object: 'Mention', history_type: 'created', o_id: 99, related_history_object: 'Ticket', related_o_id: ticket.id,
                  value_to: mentioned.id.to_s, created_by_id: agent.id, created_at: 5.hours.ago)
      History.add(history_object: 'Checklist::Item', history_type: 'checklist_item_checked', o_id: 98, related_history_object: 'Ticket', related_o_id: ticket.id,
                  value_from: 'Call the customer', value_to: 'true', created_by_id: agent.id, created_at: 4.hours.ago)
      add_history(time: 3.hours.ago, history_type: 'notification', value_to: 'nina@example.com(update:online,email)')
      History.add(history_object: 'Ticket::Article', history_type: 'email', o_id: 97, related_history_object: 'Ticket', related_o_id: ticket.id,
                  value_from: 'Your request', value_to: 'anna@example.com', created_by_id: agent.id, created_at: 2.hours.ago)

      expect(descriptions(perform).first(5)).to eq([
                                                     'sent an email to anna@example.com (subject: Your request)',
                                                     'notified nina@example.com (ticket update: online, email)',
                                                     'checked the checklist item: Call the customer',
                                                     'mentioned Max Second',
                                                     'removed tag vip',
                                                   ])
    end

    it 'names a merged ticket only to a reader who may read it' do
      readable   = create(:ticket, group:)
      unreadable = create(:ticket)
      add_history(time: 2.hours.ago, history_type: 'received_merge', id_from: readable.id, id_to: ticket.id)
      add_history(time: 1.hour.ago, history_type: 'received_merge', id_from: unreadable.id, id_to: ticket.id)

      entries = perform.content[:changes].first(2).map { |change| change[:entries].first }

      expect(entries.first).to eq(action: 'received_merge', description: 'merged another ticket into this ticket')
      expect(entries.second).to eq(action: 'received_merge', description: "merged ticket #{readable.number} into this ticket",
                                   ticket: { type: 'Ticket', id: readable.id, number: readable.number })
      expect(perform.text).not_to include(unreadable.number)
    end
  end

  describe 'references to related objects' do
    before { Setting.set('checklist', true) }

    it 'uses message positions from the article tool in structured content and model text' do
      create(:ticket_article, ticket:)
      article = create(:ticket_article, ticket:)
      History.add(history_object: 'Ticket::Article', history_type: 'updated', history_attribute: 'internal', o_id: article.id,
                  related_history_object: 'Ticket', related_o_id: ticket.id, value_from: 'false', value_to: 'true', created_by_id: agent.id, created_at: 1.hour.from_now)

      result = perform
      subject = result.content[:changes].first[:entries].first[:subject]
      expect(subject).to eq(kind: 'message', id: article.id, message_position: 2)
      expect(output_schema_errors(described_class.tool_output_schema, result.content.as_json)).to be_empty
      expect(result.text).to include('(message 2)')
      tool_call = AI::Provider::Completion::ToolCall.new(id: 'read', name: 'get_ticket_articles', arguments: { 'positions' => [subject[:message_position]] })
      read = Service::AI::Tool::Runtime::PerformCall.execute(surface: :harness, user: agent, tool_call:, audience: AI::Harness::Audience::HUMAN_AGENTS, context_object: Gql::ZammadSchema.id_from_object(ticket))
      expect(read.content[:messages].first[:id]).to eq(article.id)
    end

    it 'omits references to deleted, moved or system-notification messages' do
      moved = create(:ticket_article, ticket: create(:ticket))
      notification = create(:ticket_article, ticket:, type: Ticket::Article::Type.find_by(name: 'email'), sender: Ticket::Article::Sender.find_by(name: 'System'))
      [0, moved.id, notification.id].each_with_index do |id, index|
        History.add(history_object: 'Ticket::Article', history_type: 'created', o_id: id, related_history_object: 'Ticket', related_o_id: ticket.id,
                    created_by_id: agent.id, created_at: (index + 1).hours.from_now)
      end

      expect(perform.content[:changes].first(3).flat_map { |change| change[:entries] }).to all(satisfy { |entry| !entry.key?(:subject) })
    end

    it 'references only the current ticket checklist items' do
      checklist = create(:checklist, :empty, ticket:, created_by: agent, updated_by: agent)
      item = create(:checklist_item, checklist:, created_by: agent, updated_by: agent)
      other_checklist = create(:checklist, :empty, ticket: create(:ticket), created_by: agent, updated_by: agent)
      other = create(:checklist_item, checklist: other_checklist, created_by: agent, updated_by: agent)
      [item.id, other.id, 0].each_with_index do |id, index|
        History.add(history_object: 'Checklist::Item', history_type: 'checklist_item_checked', o_id: id, related_history_object: 'Ticket', related_o_id: ticket.id,
                    value_from: 'Call customer', value_to: 'true', created_by_id: agent.id, created_at: (index + 1).hours.from_now)
      end

      result = perform
      entries = result.content[:changes].first(3).map { |change| change[:entries].first }
      expect(entries.first(2)).to all(satisfy { |entry| !entry.key?(:subject) })
      expect(entries.last[:subject]).to eq(kind: 'checklist_item', id: item.id)
      expect(result.text).to include("(checklist item #{item.id})")
      Setting.set('checklist', false)
      expect(perform.content[:changes].first(3).flat_map { |change| change[:entries] }).to all(satisfy { |entry| !entry.key?(:subject) })
    end

    it 'does not treat a history reference as a read message' do
      article = create(:ticket_article, ticket:)
      result = perform
      returned = Service::AI::Tool::Runtime::Returned.in(conversation: nil, ticket:, except_tool: nil)
      allow(returned).to receive(:contents).and_return([result.content.deep_stringify_keys])

      expect(result.content[:changes].flat_map { |change| change[:entries] }).to include(include(subject: include(id: article.id)))
      expect(returned.article_ids_by_position).to be_empty
    end
  end

  describe 'the pages' do
    before do
      ticket
      (1..7).each { |hours| add_history(time: hours.hours.ago, history_type: 'updated', history_attribute: 'title', value_from: "Title #{hours + 1}", value_to: "Title #{hours}", author: hours.even? ? agent : customer) }
    end

    it 'pages back to the first entry, with no entry twice' do
      first  = perform({ 'limit' => 3 })
      second = perform({ 'limit' => 3, 'cursor' => first.content[:next_cursor] })

      expect(descriptions(first)).to eq(['Title: Title 2 → Title 1', 'Title: Title 3 → Title 2', 'Title: Title 4 → Title 3'])
      expect(descriptions(second).first).to eq('Title: Title 5 → Title 4')
      expect(first.content).to include(has_more: true)
      expect(first.text).to include('Older changes follow: call again with cursor')
    end

    it 'is not shifted by an entry added between two calls' do
      first = perform({ 'limit' => 3 })
      add_history(time: Time.zone.now, history_type: 'added', history_attribute: 'tag', value_to: 'urgent')

      expect(descriptions(perform({ 'limit' => 3, 'cursor' => first.content[:next_cursor] })).first).to eq('Title: Title 5 → Title 4')
    end

    it 'keeps a change whole at the end of a page' do
      add_history(time: 3.hours.ago - 2.seconds, history_type: 'added', history_attribute: 'tag', value_to: 'vip', author: customer)
      result = perform({ 'limit' => 3 })

      expect(result.content[:changes].last[:entries].pluck(:description)).to eq(['Title: Title 4 → Title 3', 'added tag vip'])
      expect(descriptions(perform({ 'limit' => 3, 'cursor' => result.content[:next_cursor] })).first).to eq('Title: Title 5 → Title 4')
    end

    it 'says when no older changes follow' do
      result = perform({ 'limit' => 100 })

      expect(result.content).to include(has_more: false)
      expect(result.content).not_to have_key(:next_cursor)
      expect(result.text).to include('No older changes follow.')
    end

    it 'refuses a cursor of another ticket or one it did not give' do
      other  = create(:ticket, group:)
      cursor = Service::AI::Tool::Runtime::Cursor.encode(offset: other.id, scope: { ticket: other.id })

      [cursor, 'not a cursor', Service::AI::Tool::Runtime::Cursor.encode(offset: 0, scope: { ticket: ticket.id }).succ].each do |given|
        expect(perform({ 'cursor' => given }).content).to include(error: 'invalid_arguments')
      end
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

    it 'returns pages that fit its output schema' do
      ticket
      History.add(history_object: 'Ticket', o_id: ticket.id, history_type: 'received_merge', id_from: create(:ticket, group:).id, id_to: ticket.id,
                  created_by_id: agent.id, created_at: 1.hour.ago)

      [{}, { limit: 1 }].each do |arguments|
        result = call({ ticket_number: ticket.number, **arguments })
        errors = output_schema_errors(described_class.tool_output_schema, result[:structuredContent])

        expect(errors).to be_empty, "#{arguments}: #{errors.first(3).join(' | ')}"
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
