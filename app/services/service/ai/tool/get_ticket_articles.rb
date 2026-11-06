# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Reads the messages of the conversation's ticket beyond what get_ticket shows: an index of them,
#   page by page, with the start of each text, the messages that hold words searched for, each with the passage around
#   the first match, or the messages chosen by their position with their text. Positions are get_ticket's: the messages the user
#   may see, without system notifications, in order. Texts are cleaned as get_ticket cleans them; "detailed" keeps the
#   quotes and signatures, where a fact may stand only there, and a search always looks there too.
class Service::AI::Tool::GetTicketArticles < Service::AI::Tool
  DEFAULT_LIMIT   = 20
  MAX_LIMIT       = 50
  MAX_POSITIONS   = 5
  EXCERPT_LENGTH  = 200
  MAX_QUERY_WORDS = 10

  # The characters the messages read by position share, so that a result stays below what a client takes from one call
  #   (Claude Code: 25,000 tokens) with each text in it twice, as text and as structured content; a longer message is cut,
  #   also alone.
  TEXT_BUDGET = 40_000

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable-next Zammad/DetectTranslatableString
  OUTPUT_SCHEMA = {
    type:       'object',
    properties: {
      ticket:        {
        type:       'object',
        properties: { type: { const: 'Ticket' }, id: { type: 'integer' }, number: { type: 'string' }, url: { type: 'string', description: 'Link to the ticket in Zammad.' } },
        required:   %w[type id number],
      },
      message_count: { type: 'integer' },
      messages:      { type: 'array', items: Service::AI::Tool::Output::Message::SCHEMA },
      query:         { type: 'array', items: { type: 'string' }, description: 'The words searched for, with query.' },
      found_count:   { type: 'integer', description: 'How many messages hold all the words, with query.' },
      has_more:      { type: 'boolean' },
      next_cursor:   { type: 'string', description: 'Pass it as cursor for the next messages of the index.' },
    },
    required:   %w[ticket message_count messages],
  }.freeze

  description 'Read the messages that get_ticket left out or cut, of one ticket of Zammad, in three ways, cheapest ' \
              'first. Without positions: an index of the messages, page by page, each with the start of its text. With ' \
              'query: the index of only the messages that hold all its words, each with the passage around the first ' \
              'match, to find where something comes up in a long ticket instead of reading it. With positions (the ' \
              'message numbers of get_ticket and of the index): those messages with their text, sharing ' \
              "#{TEXT_BUDGET.to_fs(:delimited)} characters of plain text. A message longer than this is truncated even when requested alone. Quotes and " \
              'signatures are left out unless response_format is "detailed"; query searches them as well.',
              harness: 'Without ticket_number, ticket_id or ticket_url, of the ticket of this conversation; with one of ' \
                       'them, of the ticket get_ticket read.',
              mcp:     'Name the ticket by its ticket_number, ticket_id or ticket_url. The index says how many files a ' \
                       'message has; with positions, its files are listed with their IDs, by which read_attachment ' \
                       'reads them.'
  # rubocop:disable-next Zammad/DetectTranslatableString
  title 'Get ticket articles'
  output_schema OUTPUT_SCHEMA
  effect      :read
  permission  'ticket.agent'
  offered_in  :harness, :mcp
  audiences   :human_agents
  always_loaded

  loads :ticket, type: ::Ticket, pundit_method: :agent_read_access?, named: true

  parameter :positions, type: :array, items: { type: 'integer' },
                        description: "The numbers of the messages to read with their text, at most #{MAX_POSITIONS}."
  parameter :query, type:        :string,
                    description: "Words to find in the messages, at most #{MAX_QUERY_WORDS}: an error code, a host name, a " \
                                 'name. A message is found when it holds all of them, each as a whole word, in any case ' \
                                 '(without positions).'
  parameter :response_format, type: :string, enum: %w[concise detailed], default: 'concise',
                              description: 'concise: without the quotes and signatures of replies. detailed: with them, ' \
                                           'e.g. for a phone number in a signature.'
  parameter :limit, type: :integer, minimum: 1, maximum: MAX_LIMIT, default: DEFAULT_LIMIT,
                    description: 'How many messages the index lists (without positions).' # rubocop:disable Zammad/DetectTranslatableString
  parameter :cursor, type: :string, description: 'next_cursor of the previous index, for the next messages.'

  def execute
    return positions_error if positions && invalid_positions?
    return query_error if searching? && (query_words.empty? || query_words.size > MAX_QUERY_WORDS)
    return Service::AI::Tool::Runtime::Result.error('invalid_arguments', "cursor is no next_cursor of this index. #{CURSOR_HINT} the first message.") if !positions && offset.nil?

    Service::AI::Tool::Runtime::Result.ok(content, text:)
  end

  private

  def positions
    argument(:positions)&.uniq
  end

  def detailed?
    argument(:response_format) == 'detailed'
  end

  # positions read the messages a search found already; the query is not applied to them.
  def searching?
    !positions && !argument(:query).nil?
  end

  def query_words
    @query_words ||= Service::AI::Tool::Search::WholeWord.words(argument(:query))
  end

  def query_patterns
    @query_patterns ||= query_words.map { |word| Service::AI::Tool::Search::WholeWord.pattern(word) }
  end

  def query_error
    Service::AI::Tool::Runtime::Result.error('invalid_arguments', "Pass one to #{MAX_QUERY_WORDS} words as query.")
  end

  def invalid_positions?
    positions.empty? || positions.size > MAX_POSITIONS || positions.any? { |position| !position.between?(1, article_count) }
  end

  def positions_error
    Service::AI::Tool::Runtime::Result.error(
      'invalid_arguments',
      "Pass one to #{MAX_POSITIONS} positions between 1 and #{article_count}, the messages of this ticket."
    )
  end

  # nil for a cursor this tool did not give, or one beyond the messages listed.
  def offset
    value = cursor_offset
    value if value && (value.zero? || value < listed_count)
  end

  # The ticket's messages make the index, however the caller named the ticket and whatever it shows of them; a search's
  #   pages are its own.
  def cursor_scope
    { ticket: ticket.id, query: (query_words.map(&:downcase) if searching?) }.compact
  end

  def listed_count
    searching? ? found.size : article_count
  end

  # Position and article of each message that holds every word, in the text the search reads: every message is cleaned
  #   for it, not only a page.
  def found
    @found ||= articles.to_a.each_with_index.filter_map do |article, index|
      text = searched_texts.fetch(article.id, '')
      [index + 1, article] if query_patterns.all? { |pattern| text.match?(pattern) }
    end
  end

  def searched_texts
    @searched_texts ||= clean(articles.to_a, keep_quotes: true)
  end

  # The same articles GraphQL lists for the user, numbered as get_ticket numbers them.
  def articles
    @articles ||= Service::AI::Tool::TicketMessages.of(ticket, user: current_user)
      # Cleaning reads each message's sender, type and writer; a page holds up to 50.
      .preload(:sender, :type, :created_by, :origin_by)
  end

  def article_count
    @article_count ||= articles.count
  end

  # Position and article of each message shown.
  def shown
    @shown ||= if positions then chosen
               elsif searching? then found[offset, limit + 1]
               else
                 articles.offset(offset).limit(limit + 1).to_a.each_with_index.map { |article, index| [offset + index + 1, article] }
               end
  end

  def chosen
    ids    = articles.pluck(:id)
    loaded = articles.where(id: ids.values_at(*positions.map(&:pred))).index_by(&:id)

    positions.sort.map { |position| [position, loaded.fetch(ids[position - 1])] }
  end

  def limit
    argument(:limit)
  end

  def page
    positions ? shown : shown.first(limit)
  end

  def more?
    !positions && shown.size > limit
  end

  def messages
    @messages ||= page.map do |position, article|
      text = cleaned_texts.fetch(article.id, '')

      Service::AI::Tool::Output::Message.part(
        article, position:, text:, length: positions ? lengths.fetch(position) : EXCERPT_LENGTH, excerpt: !positions, passage: passage(text),
        attachment_count: (attachment_counts[article.id] if !positions)
      )
    end
  end

  # For the excerpts of the page at once, so that a longer page costs no more queries.
  def attachment_counts
    @attachment_counts ||= Service::AI::Tool::Output::Message.attachment_counts(articles.where(id: page.map { |_position, article| article.id }))
  end

  def passage(text)
    return if !searching?

    Service::AI::Tool::Output.passage_at(text, Regexp.union(query_patterns), length: EXCERPT_LENGTH)
  end

  def lengths
    @lengths ||= begin
      full = page.map { |_position, article| cleaned_texts.fetch(article.id, '').length }

      page.map(&:first).zip(Service::AI::Tool::Output.shared_lengths(full, budget: TEXT_BUDGET)).to_h
    end
  end

  # The first message keeps its quotes, as in get_ticket: it is what the customer asked. A search shows the texts it
  #   searched, quotes included, so that the passage holds the match.
  def cleaned_texts
    return searched_texts if searching?

    @cleaned_texts ||= clean(page.map(&:second), skip_quotes_strip_first_article: page.first&.first == 1, keep_quotes: detailed?)
  end

  def clean(articles, **)
    Service::AI::Ticket::PreProcessArticleContent
      .execute(articles:, skip_ocr: true, **)
      .to_h { |article| [article[:id], article[:text].to_s.strip] }
  end

  def content
    @content ||= {
      ticket:        { type: 'Ticket', id: ticket.id, number: ticket.number },
      message_count: article_count,
      query:         (query_words if searching?),
      found_count:   (found.size if searching?),
      messages:      messages.map(&:content),
      has_more:      (more? if !positions),
      next_cursor:   (next_cursor_at(offset + limit) if more?),
    }.compact
  end

  def text
    [AI::PromptText.xml_text(header), *messages.map(&:text), footer].compact.join("\n\n")
  end

  def header
    count = "Ticket #{ticket.number} has #{article_count} #{'message'.pluralize(article_count)}"
    return "#{count}; shown below with their text: #{page.map(&:first).join(', ')}." if positions
    return search_header(count) if searching?
    return "#{count}." if page.empty?

    "#{count}; the index of #{page.first.first} to #{page.last.first} below shows the start of each."
  end

  def search_header(count)
    words = query_words.map { |word| "\"#{word}\"" }.join(', ')
    return "#{count}; none of them holds all of #{words}. Nothing more to read for these words." if found.empty?

    holding = "#{found.size} of them #{found.one? ? 'holds' : 'hold'} all of #{words}"

    "#{count}; #{holding}. Below the found messages at #{page.map(&:first).join(', ')}, " \
      'each with the passage around the first match.'
  end

  def footer
    return [alone_note, quotes_note].compact.join("\n\n").presence if positions
    return if page.empty?

    more = more? ? "More follow: call again with the same arguments and cursor \"#{content[:next_cursor]}\"." : 'No more follow.' # rubocop:disable Zammad/DetectTranslatableString
    "#{more} Call again with positions to read messages with their text.#{search_quotes_note}"
  end

  # The search looked into quotes and signatures, which positions leave out by default.
  def search_quotes_note
    return if !searching? || detailed?

    ' Add response_format "detailed" to keep the quotes and signatures a match may stand in.'
  end

  # A message cut only because the others shared its characters gets all of them when asked for alone.
  def alone_note
    cut = messages.filter_map { |message| message.content[:position] if message.content[:truncated] }
    return if cut.empty? || positions.one?

    "Cut as the messages share #{TEXT_BUDGET.to_fs(:delimited)} characters: #{cut.join(', ')}. Call again with one of " \
      "these positions alone, which gives it all #{TEXT_BUDGET.to_fs(:delimited)} characters."
  end

  def quotes_note
    return if detailed?

    'Quotes and signatures of replies are left out: call again with response_format "detailed" to keep them.' # rubocop:disable Zammad/DetectTranslatableString
  end
end
