# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Reads what happened to one ticket, as the ticket view's history shows it: each change with who made it — a
#   person, or the trigger, scheduler, postmaster filter, macro or AI agent it came from —, when, and the field's old and
#   new value in words; tags, mentions, merges, the checklist, time events, notifications and sent emails among them.
#   Newest first, in pages; a page ends where a change of one issuer and moment ends, as Service::History::Group groups
#   them, and the next page starts below the oldest entry given, so that an entry added meanwhile shifts nothing.
class Service::AI::Tool::GetTicketHistory < Service::AI::Tool
  DEFAULT_LIMIT = 30
  MAX_LIMIT     = 100

  # Entries of one issuer this close together are one change, as the ticket view groups them.
  GROUP_INTERVAL = Service::History::Group::INTERVAL

  # Written for the model, like every text a tool returns, so not translated.
  TICKET_PROPERTIES = {
    type:   { const: 'Ticket' },
    id:     { type: 'integer' },
    number: { type: 'string' },
    url:    { type: 'string', description: 'Link to the ticket in Zammad.' }, # rubocop:disable Zammad/DetectTranslatableString
  }.freeze

  ENTRY_SCHEMA = {
    type:       'object',
    properties: {
      action:      { type: 'string', description: 'The kind of entry, as Zammad records it: created, updated, added, removed, merged_into, notification, ….' }, # rubocop:disable Zammad/DetectTranslatableString
      description: { type: 'string', description: 'The entry in words.' }, # rubocop:disable Zammad/DetectTranslatableString
      field:       { type: 'string', description: 'The changed field by its label.' }, # rubocop:disable Zammad/DetectTranslatableString
      field_key:   { type: 'string', description: 'The stable attribute name, independent of its display label.' }, # rubocop:disable Zammad/DetectTranslatableString
      subject:     {
        type:       'object',
        properties: {
          kind:             { enum: %w[message checklist_item] },
          id:               { type: 'integer' },
          message_position: { type: 'integer', description: 'Current position to pass to get_ticket_articles to read this message.' }, # rubocop:disable Zammad/DetectTranslatableString
        },
        required:   %w[kind id],
      },
      from:        { type: 'string' },
      to:          { type: 'string' },
      ticket:      {
        type:       'object',
        properties: TICKET_PROPERTIES,
        required:   %w[type id number],
      },
    },
    required:   %w[action description],
  }.freeze

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable-next Zammad/DetectTranslatableString
  OUTPUT_SCHEMA = {
    type:       'object',
    properties: {
      ticket:      {
        type:       'object',
        properties: TICKET_PROPERTIES,
        required:   %w[type id number],
      },
      entry_count: { type: 'integer', description: 'How many entries the ticket\'s history holds.' },
      changes:     {
        type:  'array',
        items: {
          type:       'object',
          properties: {
            time:    { type: 'string' },
            issuer:  {
              type:       'object',
              properties: {
                name:    { type: 'string' },
                source:  { type: 'string', description: 'What made the change instead of a person: Trigger, Scheduler, Postmaster filter, Macro or AI agent.' },
                type:    { const: 'User' },
                id:      { type: 'integer' },
                deleted: { type: 'boolean' },
                url:     { type: 'string', description: 'Link to the user in Zammad.' },
              },
              required:   %w[name],
            },
            entries: { type: 'array', items: ENTRY_SCHEMA },
          },
          required:   %w[time issuer entries],
        },
      },
      has_more:    { type: 'boolean' },
      next_cursor: { type: 'string', description: 'Pass it as cursor for the older changes.' },
    },
    required:   %w[ticket entry_count changes has_more],
  }.freeze

  description 'Read what happened to one ticket of Zammad, as its history in Zammad shows it: who changed which ' \
              'field from which value to which and when — state, group, owner, priority and the other fields —, tags, ' \
              'mentions, merges, the checklist, time events, notifications and sent emails. A change made by a ' \
              'trigger, a scheduler, a postmaster filter, a macro or an AI agent names it. Newest first, page by page. ' \
              'Read a referenced message with get_ticket_articles using its message_position as a position.',
              harness: 'Without ticket_number, ticket_id or ticket_url, of the ticket of this conversation; with one of ' \
                       'them, of the ticket get_ticket read.',
              mcp:     'Name the ticket by its ticket_number, ticket_id or ticket_url.'
  # rubocop:disable-next Zammad/DetectTranslatableString
  title 'Get ticket history'
  output_schema OUTPUT_SCHEMA
  effect      :read
  permission  'ticket.agent'
  offered_in  :harness, :mcp
  audiences   :human_agents

  loads :ticket, type: ::Ticket, pundit_method: :agent_read_access?, named: true

  parameter :limit, type: :integer, minimum: 1, maximum: MAX_LIMIT, default: DEFAULT_LIMIT,
                    description: 'How many entries a page holds at least; a change of several entries comes whole.' # rubocop:disable Zammad/DetectTranslatableString
  parameter :cursor, type: :string, description: 'next_cursor of the previous page, for the older changes.'

  def execute
    return Service::AI::Tool::Runtime::Result.error('invalid_arguments', "cursor is no next_cursor of this history. #{CURSOR_HINT} the newest change.") if anchor.nil?

    Service::AI::Tool::Runtime::Result.ok(content, text:)
  end

  private

  def limit
    argument(:limit)
  end

  # The ticket's history however the caller named the ticket; the cursor holds the ID of the oldest entry given.
  def cursor_scope
    { ticket: ticket.id }
  end

  def history
    @history ||= History
      .list('Ticket', ticket.id, ticket.history_relation_object, raw: true)
      .reorder(created_at: :desc, id: :desc)
      .preload(:history_type, :history_object, :history_attribute)
  end

  def entry_count
    @entry_count ||= history.count
  end

  # :start without a cursor, the oldest entry an earlier page gave, nil for a cursor not given for this history.
  def anchor
    return @anchor if defined?(@anchor)

    id = cursor_offset
    @anchor = if id.nil? then nil
              elsif id.zero? then :start
              else
                history.find_by(id:)
              end
  end

  def older_than(entry)
    history.where('histories.created_at < :at OR (histories.created_at = :at AND histories.id < :id)', at: entry.created_at, id: entry.id)
  end

  def remaining
    anchor == :start ? history : older_than(anchor)
  end

  # The entries of the page: at least the limit, then on to the end of the change they stopped in.
  def page
    @page ||= begin
      entries = remaining.limit(limit).to_a
      entries.size == limit ? entries + rest_of_change(group(entries).last) : entries
    end
  end

  def rest_of_change(change)
    older_than(change.last)
      .where(created_at: (change.first.created_at - GROUP_INTERVAL)..)
      .to_a
      .take_while { |entry| issuer_key(entry) == issuer_key(change.first) }
  end

  # Consecutive entries of one issuer within the interval of the change's newest one.
  def group(entries)
    entries.each_with_object([]) do |entry, changes|
      current = changes.last
      if current && issuer_key(current.first) == issuer_key(entry) && current.first.created_at - entry.created_at <= GROUP_INTERVAL
        current << entry
      else
        changes << [entry]
      end
    end
  end

  def more?
    page.any? && older_than(page.last).exists?
  end

  def issuer_key(entry)
    entry.sourceable_type.present? ? [entry.sourceable_type, entry.sourceable_id] : ['User', entry.created_by_id]
  end

  def changes
    @changes ||= group(page).map do |entries|
      issuer = Service::AI::Tool::Output::HistoryIssuer.of(entries.first, users:, readable: method(:readable?))
      words  = entries.map { |entry| history_entry(entry) }

      { time: Service::AI::Tool::Output.time(entries.first.created_at), issuer:, entries: words }
    end
  end

  def history_entry(entry)
    words = Service::AI::Tool::Output::HistoryEntry.of(entry, ticket:, users:, attributes:, readable: method(:readable?))
    subject = subjects[[entry.history_object&.name, entry.o_id]]
    return words if !subject

    reference = subject[:kind] == 'message' ? "message #{subject[:message_position]}" : "checklist item #{subject[:id]}"
    words.merge(subject:, description: "#{words[:description]} (#{reference})")
  end

  # A reference does not mean the message body was read: Returned collects `position`, not `message_position`.
  def subjects
    @subjects ||= message_subjects.merge(checklist_subjects)
  end

  def subject_ids(object)
    page.select { |entry| entry.history_object&.name == object }.to_set(&:o_id)
  end

  def message_subjects
    ids = subject_ids('Ticket::Article')
    return {} if ids.empty?

    Service::Ticket::Article::List.with_current_user(current_user).execute(ticket:)
      .without_system_notifications.pluck(:id).each_with_index.with_object({}) do |(id, index), references|
        next if ids.exclude?(id)

        references[['Ticket::Article', id]] = { kind: 'message', id:, message_position: index + 1 }
      end
  end

  def checklist_subjects
    ids = subject_ids('Checklist::Item')
    return {} if ids.empty? || !ticket.checklist || !readable?(ticket.checklist)

    ticket.checklist.items.where(id: ids.to_a).pluck(:id).to_h do |id|
      [['Checklist::Item', id], { kind: 'checklist_item', id: }]
    end
  end

  def attributes
    @attributes ||= Service::AI::Tool::Output::HistoryEntry.attributes(page)
  end

  # The users the page names — as issuers and mentioned —, read once.
  def users
    @users ||= begin
      ids = page.flat_map do |entry|
        [(entry.created_by_id if entry.sourceable_type.blank?), (entry.value_to.to_i if entry.history_object&.name == 'Mention')]
      end

      ::User.where(id: ids.compact.uniq).index_by(&:id)
    end
  end

  def content
    @content ||= {
      ticket:      { type: 'Ticket', id: ticket.id, number: ticket.number },
      entry_count:,
      changes:,
      has_more:    more?,
      next_cursor: (next_cursor_at(page.last.id) if more?),
    }.compact
  end

  def text
    [AI::PromptText.xml_text(header), history_text, footer].compact.join("\n\n")
  end

  def header
    count = "Ticket #{ticket.number} has #{entry_count} history #{'entry'.pluralize(entry_count)}"
    return "#{count}; none older than the cursor." if page.empty?

    "#{count}; below #{page.size} of them, newest first, grouped by who made a change and when."
  end

  # Names and values in it may come from whoever wrote a title, a tag or a mail: marked as the ticket's text.
  def history_text
    return if changes.empty?

    lines = changes.flat_map do |change|
      ["#{change[:time]} · #{change[:issuer][:name]}", *change[:entries].map { |entry| "- #{entry[:description]}" }]
    end

    AI::PromptText.marked_text(lines.join("\n"), source: 'ticket', field: 'history')
  end

  def footer
    return if page.empty?

    more? ? "Older changes follow: call again with cursor \"#{content[:next_cursor]}\"." : 'No older changes follow.' # rubocop:disable Zammad/DetectTranslatableString
  end
end
