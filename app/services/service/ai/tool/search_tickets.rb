# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Searches the tickets the user may see by words — with Zammad's search syntax where Elasticsearch runs —, by filters
#   given as names, or both, newest first unless the caller sorts otherwise, as the products' MCP servers search: one search narrows by its parameters,
#   and the user's permissions set the limit. Without either it lists the newest tickets: the read scope, the limit and
#   the paging hold all the same. Each ticket is a row as in every tool, with the start of its first message
#   (Service::AI::Tool::Output). The ticket of the conversation is the base of its context: it is not listed again, only
#   named where it matches.
class Service::AI::Tool::SearchTickets < Service::AI::Tool
  include Service::AI::Tool::Concerns::Sorting

  DEFAULT_LIMIT = 30
  MAX_LIMIT     = 50
  SORT_FIELDS   = %w[created_at updated_at last_contact_at close_at escalation_at].freeze

  # rubocop:disable-next Zammad/DetectTranslatableString
  FAILED_TEXT = 'The search could not run: the syntax of the query may be wrong, or the search does not answer. ' \
                'Check the syntax or search by plain words; if that fails as well, tell the user that the ticket ' \
                'search does not work right now.'.freeze
  # rubocop:disable-next Zammad/DetectTranslatableString
  NO_SYNTAX_TEXT = 'This Zammad searches without Elasticsearch and takes plain words only: a field such as title: or ' \
                   'created_at: is not searched. Search by words or by the filters; for the tickets since a time, ' \
                   'page until a ticket was created before it.'.freeze

  # Written for the model, like every text a tool returns, so not translated. The conversation's ticket is a fact of the
  #   harness only.
  # rubocop:disable-next Zammad/DetectTranslatableString
  OUTPUT_SCHEMA = {
    type:       'object',
    properties: {
      query:       { type: 'string', description: 'The words searched for.' },
      filters:     { type: 'array', items: { type: 'string' }, description: 'The filters as they were resolved, e.g. "customer Anna Example (anna@example.com)".' },
      tickets:     { type: 'array', items: Service::AI::Tool::Output::ListedTicket.schema },
      has_more:    { type: 'boolean' },
      next_cursor: { type: 'string', description: 'Pass it as cursor, with the same other arguments, for the next tickets.' },
    },
    required:   %w[tickets has_more],
  }.freeze

  description 'Search the tickets of Zammad the user may see, by a query, by filters or both; without either, it ' \
              'lists the newest tickets. Tickets come newest created first; sort_by and order_by sort otherwise, e.g. sort_by "created_at" with order_by "asc" for the oldest first. The query takes words or Lucene query ' \
              'syntax, as Zammad\'s search box does: fields such as title:printer, article.body:"error 500" or ' \
              'tags:vip, dates such as created_at:>now-1d or updated_at:>now-1d, quotes for a phrase, AND, OR, NOT. Use ' \
              'the filters for customer, organization, state, owner, group and priority, the query for everything ' \
              'else. Filters take names: customer (a name, an email or "ID 5"), organization (a name or "ID 12"), ' \
              'state_type_category, state (one or more exact state names), owner ("me", "nobody", a name or an ' \
              'email), group and priority; a name that fits several records or none is answered with the candidates ' \
              'or the valid values. search_users and search_organizations find a person or an organization by a ' \
              'part of the name and give the ID. Each row names the ticket\'s customer and organization, with response_format "detailed" also the start of its first ' \
              'message; get_ticket reads a ticket in full. Pass ' \
              'next_cursor as cursor, with the same other arguments, for the next tickets.',
              harness: 'For the customer of this conversation\'s ticket, pass the email get_ticket shows, or the name ' \
                       'where it shows none.',
              mcp:     'Each row links to its ticket. The saved ticket lists the user works from, such as their ' \
                       'escalated tickets, are overviews: get_overview_tickets reads one.'
  # rubocop:disable-next Zammad/DetectTranslatableString
  title 'Search tickets'
  output_schema OUTPUT_SCHEMA
  effect      :read
  permission  'ticket.agent'
  offered_in  :harness, :mcp
  audiences   :human_agents
  always_loaded
  searches

  # rubocop:disable Zammad/DetectTranslatableString
  parameter :query, type: :string, description: 'Words to look for, e.g. "outlook sync", or Lucene query syntax, e.g. "outlook AND created_at:>now-1d".'
  parameter :customer, type: :string, description: 'The customer: a name, an email or "ID 5".'
  parameter :organization, type: :string, description: 'The organization: its name or "ID 12".'
  parameter :state_type_category, type: :string, enum: %w[open closed],
                                  description: 'open: every ticket still to be worked on, whatever its state (new, open, pending). closed: the closed ones.'
  parameter :state, type: :array, items: { type: 'string' }, description: 'One or more exact state names, e.g. ["pending reminder"].'
  parameter :owner, type: :string, description: '"me", "nobody", or an agent: a name or an email.'
  parameter :group, type: :string, description: 'The group: its name.'
  parameter :priority, type: :string, description: 'The priority: its name.'
  parameter :limit, type: :integer, minimum: 1, maximum: MAX_LIMIT, default: DEFAULT_LIMIT, description: 'How many tickets to list.'
  parameter :cursor, type: :string, description: 'next_cursor of the previous result, for the next tickets.'
  parameter :response_format, type: :string, enum: %w[concise detailed], default: 'concise',
                              description: 'concise: the rows alone. detailed: each row with the start of the ticket\'s first message.'
  # rubocop:enable Zammad/DetectTranslatableString
  sortable SORT_FIELDS, default: 'the newest created first'

  def execute
    return search_result if argument(:cursor)

    Service::AI::Tool::Runtime::SearchCount.noted_result(search_result, run:)
  end

  private

  attr_reader :next_cursor

  def search_result
    return Service::AI::Tool::Runtime::Result.error('invalid_arguments', "cursor is no next_cursor of this search. #{CURSOR_HINT} the first ticket.") if offset.nil?
    return Service::AI::Tool::Runtime::Result.error('invalid_arguments', NO_SYNTAX_TEXT) if !SearchIndexBackend.enabled? && Service::AI::Tool::Search::QueryWords.field?(query)

    Service::AI::Tool::Runtime::Result.ok(content, text:)
  rescue Filters::Invalid => e
    Service::AI::Tool::Runtime::Result.error(e.code, e.message)
  rescue SearchIndexBackend::SearchFailedError => e
    Rails.logger.error "AI tool #{self.class.tool_name} could not search: #{e.message}"
    Service::AI::Tool::Runtime::Result.error('search_failed', FAILED_TEXT)
  end

  def content
    @content ||= {
      query:,
      filters:                     filters.descriptions.presence,
      tickets:                     rows.map(&:content),
      conversation_ticket_matches: (true if conversation_ticket_match),
      has_more:                    more?,
      next_cursor:                 more? ? next_cursor : nil,
    }.compact
  end

  # A query that is nothing but syntax, such as a lone wildcard, has no words: a model sends `*` for every ticket.
  def query
    Service::AI::Tool::Search::QueryWords.search_text(argument(:query))
  end

  def limit
    argument(:limit)
  end

  def filters
    @filters ||= Filters.new(user: current_user, arguments:)
  end

  def offset
    cursor_offset
  end

  # The ticket the conversation is about, where it is one.
  def conversation_ticket_id
    gid = GlobalID.parse(context_object.to_s)
    gid.model_id.to_i if gid&.model_name == 'Ticket'
  end

  # Loaded once, so that the rows, the text and the paging see the same tickets.
  def found
    @found ||= filters.match_nothing? ? [] : find_tickets
  end

  # Said on the first page, also where the page ends before the search reaches it; a page lists it in no row and counts
  #   it toward no limit.
  def conversation_ticket_match
    return @conversation_ticket_match if defined?(@conversation_ticket_match)

    found
    @conversation_ticket_match ||= search_conversation_ticket if offset.zero?
  end

  # The search as for the list, for the conversation's ticket alone.
  def search_conversation_ticket
    return if conversation_ticket_id.nil? || filters.match_nothing?

    ids = ::Ticket.search(current_user:, query:, condition: filters.conditions.merge('ticket.id' => { operator: 'is', value: [conversation_ticket_id] }), limit: 1, full: false, raise_on_failure: true) || []
    readable_tickets(ids.map(&:to_i))[conversation_ticket_id]
  end

  def find_tickets
    matches = []
    search_offset = offset

    loop do
      ids = search(search_offset).map(&:to_i)
      readable = readable_tickets(ids)

      ids.each_with_index do |id, index|
        next if !readable.key?(id)

        if id == conversation_ticket_id
          @conversation_ticket_match = readable[id]
          next
        end

        matches << readable[id]
        @next_cursor = next_cursor_at(search_offset + index + 1) if matches.size == limit
        break if matches.size > limit
      end

      break if matches.size > limit || ids.size <= limit

      search_offset += ids.size
    end

    matches
  end

  # Indexed groups, customers and the other filtered fields may lag behind the database while their update job is
  #   pending.
  def readable_tickets(ids)
    filters.apply(TicketPolicy::ReadScope.new(current_user).resolve)
      .includes(:customer, :organization)
      .where(id: ids)
      .index_by(&:id)
  end

  def search(search_offset)
    ::Ticket.search(
      current_user:     current_user,
      query:            query,
      condition:        filters.conditions,
      limit:            limit + 1,
      offset:           search_offset,
      sort_by:          sorting.first,
      order_by:         sorting.last,
      full:             false,
      # A query Elasticsearch cannot run must not read as one without matches.
      raise_on_failure: true,
    ) || []
  end

  # The ID keeps tickets created at the same time, as an import creates them, in one order across pages.
  def sorting
    search_sorting('created_at')
  end

  def page
    @page ||= found.first(limit)
  end

  def more?
    found.size > limit
  end

  def first_articles
    @first_articles ||= argument(:response_format) == 'detailed' ? Service::AI::Tool::Output::ListedTicket.first_articles(page, user: current_user) : {}
  end

  def rows
    @rows ||= page.map { |ticket| Service::AI::Tool::Output::ListedTicket.row(ticket, article: first_articles[ticket.id]) }
  end

  def text
    # A name with a line break would otherwise start a line of its own.
    header = AI::PromptText.xml_text(["Tickets#{" matching \"#{query}\"" if query}", *content[:filters]].join(' · ').squish)
    return "#{header}: #{only_conversation_ticket_text}" if content[:tickets].empty? && conversation_ticket_match
    return "#{header}: none." if content[:tickets].empty?

    more = content[:has_more] ? "More follow: call again with the same arguments and cursor \"#{content[:next_cursor]}\"." : 'No more follow.' # rubocop:disable Zammad/DetectTranslatableString

    ["#{header}:", conversation_ticket_text, *rows.map(&:text), more, Service::AI::Tool::Output::Ticket::LISTED_NOTE].compact.join("\n\n")
  end

  # The model left the base of its context out of a list unless it was told that it matches.
  def conversation_ticket_text
    return if conversation_ticket_match.nil?

    "The ticket of this conversation, #{conversation_ticket_match.number}, matches as well. It is not listed again: " \
      'its facts are in the context, and get_ticket reads it.'
  end

  def only_conversation_ticket_text
    "only the ticket of this conversation, #{conversation_ticket_match.number}, matches. Its facts are in the context, " \
      'and get_ticket reads it.'
  end
end
