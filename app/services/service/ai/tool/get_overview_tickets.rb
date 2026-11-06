# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Reads the tickets of one of the user's overviews as Zammad shows them: the overview's conditions — many of which no
#   search filter covers, such as a pending time reached or mentions —, its grouping and order, and its count. Each
#   ticket is the row of a ticket search, with the values the overview groups and sorts by. The overview is named by its
#   ID or by its name, so that no list is needed first; a name that fits none or several answers with the list. In a
#   conversation about an overview, an unnamed one is that overview, while the user still works from it.
class Service::AI::Tool::GetOverviewTickets < Service::AI::Tool
  include Service::AI::Tool::Concerns::Sorting

  DEFAULT_LIMIT = 30
  MAX_LIMIT     = 50

  # The facts every ticket row has already; another field the overview groups or sorts by is added to the row.
  ROW_FIELDS = %w[number title state customer organization created_at updated_at].freeze

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable Zammad/DetectTranslatableString
  OUTPUT_SCHEMA = {
    type:       'object',
    properties: {
      overview:    Service::AI::Tool::Output::Overview::SCHEMA,
      order:       {
        type:        'object',
        description: 'How the overview lists its tickets: by a field, ascending or descending, within its groups where it groups them.',
        properties:  {
          by:        { type: 'string' },
          direction: { enum: %w[ascending descending] },
          group_by:  { type: 'string' },
        },
        required:    %w[by direction],
      },
      tickets:     {
        type:  'array',
        items: Service::AI::Tool::Output::ListedTicket.schema(
          sorted_by: {
            type:        'array',
            description: 'The values the overview groups and sorts by, where the row has no such fact.',
            items:       {
              type:       'object',
              properties: { field: { type: 'string' }, value: { type: 'string' } },
              required:   %w[field],
            },
          },
        ),
      },
      has_more:    { type: 'boolean' },
      next_cursor: { type: 'string', description: 'Pass it as cursor, with the same overview and order, for the next tickets.' },
    },
    required:   %w[overview order tickets has_more],
  }.freeze

  description 'Read the tickets of one of the user\'s overviews in Zammad — the saved ticket lists an admin set up for ' \
              'the team, such as "My Assigned Tickets", "Escalated Tickets" or "My Pending Reached Tickets" — as Zammad ' \
              'shows them: in the overview\'s order unless sort_by and order_by sort otherwise, with its count, each row naming the ticket\'s customer and ' \
              'organization and linking to it, with response_format "detailed" also the start of its first message. ' \
              'Name the overview by its ID or ' \
              'by its name as the user says it, in the user\'s language or in English; a name that fits none or several ' \
              'answers with the user\'s overviews. Many overviews hold what search_tickets cannot filter for, such as a ' \
              'pending time reached, mentions or an escalation due. get_ticket reads a ticket in full. Pass next_cursor ' \
              'as cursor, with the same overview and order, for the next tickets.',
              harness: 'In a conversation about an overview, it reads that overview without being told which.',
              mcp:     'list_overviews is not needed first.'
  title 'Get overview tickets'
  # rubocop:enable Zammad/DetectTranslatableString
  output_schema OUTPUT_SCHEMA
  effect      :read
  permission  'ticket.agent'
  offered_in  :mcp, :harness
  audiences   :human_agents

  # rubocop:disable Zammad/DetectTranslatableString
  parameter :overview_id, type: :integer, description: 'The overview\'s ID.', mcp_description: 'The overview\'s ID, as list_overviews shows it.'
  parameter :overview, type: :string, description: 'The overview\'s name, e.g. "My Assigned Tickets" or "Escalated"; a part of it fits where only one overview has it.'
  parameter :limit, type: :integer, minimum: 1, maximum: MAX_LIMIT, default: DEFAULT_LIMIT, description: 'How many tickets to list.'
  parameter :cursor, type: :string, description: 'next_cursor of the previous result, for the next tickets.'
  sortable Service::AI::Tool::SearchTickets::SORT_FIELDS, default: "the overview's own order"
  parameter :response_format, type: :string, enum: %w[concise detailed], default: 'concise',
                              description: 'concise: the rows alone. detailed: each row with the start of the ticket\'s first message.'
  # rubocop:enable Zammad/DetectTranslatableString

  def execute
    return Service::AI::Tool::Runtime::Result.error('invalid_arguments', "Give overview_id or overview. #{user_overviews.listed}") if !named? && starting_overview_id.nil?
    return Service::AI::Tool::Runtime::Result.error('invalid_arguments', "cursor is no next_cursor of this overview. #{CURSOR_HINT} the first ticket.") if offset.nil?

    Service::AI::Tool::Runtime::Result.ok(content, text:)
  rescue Service::AI::Tool::Lookup::UserOverviews::Invalid => e
    Service::AI::Tool::Runtime::Result.error(e.code, e.message)
  rescue ActiveRecord::RecordNotFound
    raise if named?

    Service::AI::Tool::Runtime::Result.error('not_found', 'The overview of this conversation is no longer available to the user. Read none of its tickets; tell the user.')
  end

  private

  def named?
    !argument(:overview_id).nil? || argument(:overview).to_s.strip.present?
  end

  # Over MCP there is no conversation, and a call has to name the overview.
  def starting_overview_id
    return if surface != :harness

    global_id = GlobalID.parse(context_object.to_s)
    global_id.model_id.to_i if global_id&.model_name == ::Overview.name
  end

  def user_overviews
    @user_overviews ||= Service::AI::Tool::Lookup::UserOverviews.new(current_user) # rubocop:disable Zammad/ForbidCallingServiceDirectly
  end

  def overview
    @overview ||= named? ? user_overviews.find(id: argument(:overview_id), name: argument(:overview)) : user_overviews.find(id: starting_overview_id)
  end

  def overview_row
    @overview_row ||= user_overviews.row(overview)
  end

  def limit
    argument(:limit)
  end

  def offset
    cursor_offset
  end

  # The overview, however it was named.
  def cursor_scope
    { overview_id: overview.id, sort_by: argument(:sort_by), order_by: argument(:order_by) }.compact
  end

  def content
    @content ||= {
      overview:    overview_row.content,
      order:,
      tickets:     rows.map(&:content),
      has_more:    more?,
      next_cursor: (next_cursor_at(offset + limit) if more?),
    }.compact
  end

  def order
    {
      by:        argument(:sort_by) || overview.order['by'],
      direction: direction(sorted? ? sort_direction : overview.order['direction']),
      group_by:  overview.group_by.presence,
    }.compact
  end

  def direction(value)
    value.to_s.casecmp?('DESC') ? 'descending' : 'ascending'
  end

  # Loaded once, so that the rows, the text and the paging see the same tickets.
  def found
    @found ||= user_overviews.tickets(overview, **custom_order).offset(offset).limit(limit + 1).to_a
  end

  def custom_order
    sorted? ? { order_by: argument(:sort_by), order_direction: sort_direction.upcase } : {}
  end

  def page
    @page ||= found.first(limit).tap do |tickets|
      ActiveRecord::Associations::Preloader.new(records: tickets, associations: [:customer, :organization, *list_relations]).call
    end
  end

  def more?
    found.size > limit
  end

  def list_fields
    @list_fields ||= [overview.group_by, order[:by]].compact_blank.uniq - ROW_FIELDS
  end

  # An overview stores a ticket's relations without "_id", as the interfaces show them: the owner by name.
  def list_relations
    list_fields.select { |field| ::Ticket.reflect_on_association(field.to_sym) && ::Ticket.column_names.include?("#{field}_id") }.map(&:to_sym)
  end

  # The overview's fields an admin added to tickets; never read as a plain column.
  def custom_field_names
    @custom_field_names ||= ObjectManager::Attribute.where(object_lookup_id: ObjectLookup.by_name('Ticket'), name: list_fields, editable: true).pluck(:name)
  end

  def first_articles
    @first_articles ||= argument(:response_format) == 'detailed' ? Service::AI::Tool::Output::ListedTicket.first_articles(page, user: current_user) : {}
  end

  def rows
    @rows ||= page.map do |ticket|
      values = list_fields.filter_map { |field| list_value(ticket, field) }

      Service::AI::Tool::Output::ListedTicket.row(
        ticket,
        article: first_articles[ticket.id],
        content: { sorted_by: values.map { |field, value| { field:, value: }.compact }.presence }.compact,
        facts:   values.map { |field, value| "#{field.humanize(capitalize: false)} #{value || 'none'}" },
      )
    end
  end

  # @return [Array(String, String), nil] the field and its value, nil for a field the user may not see
  def list_value(ticket, field)
    return if !field_visible?(ticket, field)
    return custom_value(ticket, field) if custom_field_names.include?(field)

    value = if list_relations.include?(field.to_sym)
              name_of(ticket.public_send(field))
            elsif ticket.has_attribute?(field) && ::Ticket.column_names.exclude?("#{field}_id")
              plain(ticket[field])
            end

    [field, value]
  end

  # A custom field as get_ticket names it, by the label of its value; free text stays out of the line, as anyone may
  #   have written it. Whether the user sees the field depends on the ticket: an agent may see it on a ticket of their
  #   groups, but not on their own ticket as its customer.
  def custom_value(ticket, field)
    attribute = visible_custom_fields(ticket)[field]
    return if attribute.nil? || Service::AI::Tool::Output::Fields.free_text_names([attribute]).any?

    [field, plain(Service::AI::Tool::Output::Fields.values(ticket, attributes: [attribute], user: current_user)[field])]
  end

  # Read once per ticket and call: building them reads every attribute of the object.
  def visible_custom_fields(ticket)
    @visible_custom_fields ||= {}
    @visible_custom_fields[ticket.id] ||= Service::AI::Tool::Output::Fields.attributes(ticket, user: current_user).index_by(&:name)
  end

  def name_of(record)
    case record
    when nil then nil
    when ::User then record.fullname
    when ::Group then record.name.split('::').join(' › ')
    else record.try(:name)&.to_s
    end
  end

  def plain(value)
    case value
    when nil, '' then nil
    when Time, ActiveSupport::TimeWithZone then Service::AI::Tool::Output.time(value)
    when Array then value.join(', ')
    else value.to_s
    end
  end

  def text
    # A list's own values may hold a line break: escaped as a whole, as every row's line is.
    header = [
      overview_row.text,
      AI::PromptText.xml_text(order_text),
    ].join(' · ')
    return "#{header}: none." if rows.empty?

    more = content[:has_more] ? "More follow: call again with the same overview, order and cursor \"#{content[:next_cursor]}\"." : 'No more follow.' # rubocop:disable Zammad/DetectTranslatableString

    ["#{header}:", *rows.map(&:text), more, Service::AI::Tool::Output::Ticket::LISTED_NOTE].join("\n\n")
  end

  def order_text
    sorted = "sorted by #{order[:by].to_s.humanize(capitalize: false)}, #{order[:direction]}"
    return sorted if order[:group_by].nil?

    "grouped by #{order[:group_by].humanize(capitalize: false)}, #{sorted}"
  end
end
