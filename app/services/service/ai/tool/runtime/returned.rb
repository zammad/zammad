# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# What the tools of a conversation returned, read from the content of their finished calls: the knowledge base answers,
#   tickets, users and organizations as rows, and the messages of one ticket by the position they were shown at. Every
#   run of the conversation counts, as a draft asked for in a later message may build on a search of an earlier one,
#   and a ticket may be read that a search of an earlier message listed.
class Service::AI::Tool::Runtime::Returned
  Found = Data.define(:rows, :messages)

  # The type a document of a connected system is stored as among the sources (AI::Harness::Sources::DOCUMENT).
  DOCUMENT = 'ExternalDocument'.freeze

  attr_reader :conversation, :ticket, :except_tool

  # @param ticket [Ticket, nil] the ticket whose messages count
  # @param except_tool [String] a tool whose results repeat what it was given, which no tool returned
  def self.in(conversation:, except_tool:, ticket: nil)
    new(conversation:, ticket:, except_tool:)
  end

  def initialize(conversation:, except_tool:, ticket: nil)
    @conversation = conversation
    @ticket       = ticket
    @except_tool  = except_tool
  end

  # @return [Set<Integer>]
  def answer_ids
    ids_of(::KnowledgeBase::Answer)
  end

  # @return [Set<Integer>]
  def ticket_ids
    ids_of(::Ticket)
  end

  # The tickets a tool read as its own object, not listed among others: what an answer may rest on, where a listed
  #   ticket is only named.
  #
  # @return [Set<Integer>]
  def read_ticket_ids
    @read_ticket_ids ||= contents.filter_map { |content| content.dig('ticket', 'id') if content.is_a?(Hash) && content['ticket'].is_a?(Hash) }.to_set
  end

  # The documents the connected systems' tools returned, each URL once, the latest call that returned it winning.
  #
  # @return [Array<Hash>] server_id, title, url and the tool_call_id of the call, as a source stores them
  def documents
    @documents ||= conversation.events
      .where(event_type: 'tool_call_finished')
      .where("payload ->> 'status' = 'ok'")
      .where("payload -> 'content' -> 'documents' IS NOT NULL")
      .pluck(:payload)
      .flat_map do |payload|
        Array(payload.dig('content', 'documents')).filter_map do |document|
          next if !document.is_a?(Hash) || document['url'].blank?

          { 'type' => DOCUMENT, 'server_id' => payload.dig('content', 'server_id'), 'title' => document['title'].presence, 'url' => document['url'], 'tool_call_id' => payload['tool_call_id'] }
        end
      end
      .reverse.uniq { |document| document['url'] }.reverse
  end

  # @param type [Class] a model the tools return as rows (Service::AI::Tool::Output.row_types)
  # @return [Set<Integer>]
  def ids_of(type)
    found.rows.fetch(type.name)
  end

  # The article of the ticket that the most recent result showed at each position. Articles of other tickets are no
  #   candidates, as a listed ticket's first message also carries position 1, and neither is an article moved to another
  #   ticket since.
  #
  # @return [Hash{Integer => Integer}] the position and the article's ID
  def article_ids_by_position
    @article_ids_by_position ||= begin
      own = ::Ticket::Article.where(ticket_id: ticket.id, id: found.messages.map(&:last)).pluck(:id).to_set

      found.messages.select { |_position, id| own.include?(id) }.to_h
    end
  end

  private

  def found
    @found ||= begin
      rows     = Service::AI::Tool::Output.row_types.index_with { Set.new }
      messages = []
      contents.each { |content| collect(content, rows, messages) }

      Found.new(rows:, messages:)
    end
  end

  # In the order of the events, so that a later result wins over an earlier one.
  def contents
    conversation.events
      .where(event_type: 'tool_call_finished')
      .where("payload ->> 'status' = 'ok'")
      .where("payload ->> 'name' IS DISTINCT FROM ?", except_tool)
      .pluck(:payload)
      .pluck('content')
  end

  # @param rows [Hash{String => Set<Integer>}] the IDs of the objects, by type
  # @param messages [Array<Array<Integer>>] the position and the ID of each message
  def collect(node, rows, messages)
    case node
    when Array
      node.each { |child| collect(child, rows, messages) }
    when Hash
      id = node['id']

      if id.is_a?(Integer)
        rows[node['type']] << id if rows.key?(node['type'])
        messages << [node['position'], id] if node['position'].is_a?(Integer)
      end

      node.each_value { |child| collect(child, rows, messages) }
    end
  end
end
