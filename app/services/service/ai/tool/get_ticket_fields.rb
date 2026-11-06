# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Lists what update_ticket can set on one ticket: the fields of the edit screen as Service::EntityAttribute::Metadata gives them
#   for the user, each with its value, whether it is required and the values it allows — for the ticket as it is, or in
#   another group or state, as the form changes when one of them changes. Without a ticket, the fields of a new one, as
#   create_ticket sets them. A client needs it only to learn the values; both tools take names without it and name the
#   valid ones when a name does not fit.
class Service::AI::Tool::GetTicketFields < Service::AI::Tool
  VALUES_CAP = 20

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable-next Zammad/DetectTranslatableString
  OUTPUT_SCHEMA = {
    type:       'object',
    properties: {
      ticket: Service::AI::Tool::Output::Ticket.schema,
      fields: {
        type:  'array',
        items: {
          type:       'object',
          properties: {
            argument:     { type: 'string', description: 'How update_ticket takes the field: an argument of its own, or "fields.<name>" in its fields object.' },
            label:        { type: 'string' },
            type:         { type: 'string', description: 'The field\'s data type in Zammad.' },
            value:        { description: 'The current value, by name or label. Missing where the field is empty.' },
            required:     { type: 'boolean' },
            values:       { type: 'array', items: { type: 'string' }, description: 'The values the field allows here, by name or label. Missing for a field without a list, and for the owner of a new ticket until a group is given.' },
            values_total: { type: 'integer', description: 'How many values the field allows, where more than the listed ones.' },
          },
          required:   %w[argument label type required],
        },
      },
    },
    required:   %w[fields],
  }.freeze

  # rubocop:disable Zammad/DetectTranslatableString
  description 'List the fields update_ticket can set on a ticket, with their current values, whether they are ' \
              'required and the values they allow there, as the ticket form in Zammad offers them. Not needed before ' \
              'a change: update_ticket takes names, and names the valid values when one does not fit. Call it to ' \
              'learn the values, such as which categories or owners there are; pass group or state to see the ' \
              'fields as they would be after moving the ticket or changing its state, and field with query to read ' \
              'one long list. Without a ticket, it lists the fields create_ticket sets on a new ticket; pass group to ' \
              'see them in that group.'
  title 'Get ticket fields'
  parameter :group, type: :string, description: 'Show the fields as they would be in this group, by its name.'
  parameter :state, type: :string, description: 'Show the fields as they would be in this state, by its name.'
  parameter :field, type: :string, description: 'Only this field, by its argument as listed, such as "owner" or "fields.product".'
  parameter :query, type: :string, description: 'With field: only values that contain these characters.'
  # rubocop:enable Zammad/DetectTranslatableString
  output_schema OUTPUT_SCHEMA
  effect      :read
  permission  'ticket.agent'
  offered_in  :mcp
  audiences   :human_agents

  # The fields the user may change, as update_ticket changes them.
  loads :ticket, type: ::Ticket, pundit_method: :agent_update_access?, named: true, optional: true

  def execute
    fields = listed_fields
    return Service::AI::Tool::Runtime::Result.error('invalid_value', "field \"#{argument(:field)}\" is no field of #{ticket ? "this ticket's" : "a new ticket's"} form. Fields: #{form_fields.pluck(:argument).join(', ')}.") if fields.empty? && argument(:field)

    Service::AI::Tool::Runtime::Result.ok({ ticket: (row.content.merge(url:) if ticket), fields: }.compact, text: text(fields))
  rescue Service::AI::Tool::Fields::EntityAttribute::Invalid => e
    Service::AI::Tool::Runtime::Result.error(e.code, e.message)
  end

  private

  def row
    @row ||= Service::AI::Tool::Output::Ticket.row(ticket)
  end

  # The ticket, or a new one, whose fields the create form shows.
  def record
    @record ||= ticket || ::Ticket.new
  end

  def url
    Service::AI::Tool::ObjectLink.url(type: 'Ticket', id: ticket.id)
  end

  # The fields as the form shows them for the ticket, in the group and the state the caller asks about.
  def fields_by_argument
    @fields_by_argument ||= Service::AI::Tool::Fields::TicketFields.settable(ticket: record, user: current_user, changes:)
  end

  # The group and the state the caller asks about, matched against what the form allows: the state against what the
  #   group allows.
  def changes
    { 'group' => :group, 'state' => :state }.each_with_object({}) do |(key, parameter), result|
      next if argument(parameter).blank?

      field = Service::AI::Tool::Fields::TicketFields.settable(ticket: record, user: current_user, changes: result)[key]
      next if field.nil?

      result[field.name] = Service::AI::Tool::Fields::EntityAttribute.resolve(field.type, argument(parameter), allowed: field.allowed).id
    end
  end

  def listed_fields
    entries = form_fields
    entries = entries.select { |entry| entry[:argument].casecmp?(argument(:field).strip) } if argument(:field).present?

    entries.map { |entry| narrowed(entry) }
  end

  def form_fields
    @form_fields ||= fields_by_argument.filter_map do |argument, field|
      next if !field.shown

      entry(argument, field)
    end
  end

  def entry(argument, field)
    values = Service::AI::Tool::Fields::EntityAttribute.values(field) if argument != 'owner' || !owners_unknown?

    {
      argument:,
      label:        field.attribute.display,
      type:         field.attribute.data_type,
      value:        Service::AI::Tool::Fields::EntityAttribute.value_text(field, record[field.name]),
      required:     field.required,
      values:       values&.first(VALUES_CAP),
      values_total: (values.size if values && values.size > VALUES_CAP),
      all_values:   values,
    }.compact
  end

  # The values that contain the query, for a caller that reads one long list.
  def narrowed(entry)
    return entry.except(:all_values) if argument(:field).blank? || argument(:query).blank? || entry[:all_values].nil?

    values = entry[:all_values].select { |value| value.downcase.include?(argument(:query).strip.downcase) }

    entry.merge(values: values.first(VALUES_CAP), values_total: (values.size if values.size > VALUES_CAP)).compact.except(:all_values)
  end

  def text(fields)
    lines = fields.map { |field| AI::PromptText.xml_text(field_line(field)) }
    scope = [("in group #{argument(:group)}" if argument(:group).present?), ("in state #{argument(:state)}" if argument(:state).present?)].compact

    [
      (row.text if ticket),
      AI::PromptText.xml_text(ticket ? update_line(scope) : create_line(scope)),
      *lines,
      *free_texts(fields),
      (url if ticket),
    ].compact.join("\n")
  end

  def update_line(scope)
    "The fields update_ticket can set#{" #{scope.join(' and ')}" if scope.any?}: state, priority, group, owner and " \
      'pending_time as arguments of their own, custom fields in its fields object, by the names listed.'
  end

  def create_line(scope)
    "The fields create_ticket sets on a new ticket#{" #{scope.join(' and ')}" if scope.any?}: those not in its fields " \
      "object as arguments of their own, custom fields in its fields object, by the names listed.#{' The owners depend on the group: pass group to list them.' if owners_unknown?}"
  end

  # A new ticket's owners are the agents of its group, so the form lists none before a group is chosen.
  def owners_unknown?
    ticket.nil? && argument(:group).blank?
  end

  def field_line(field)
    value  = field_value_text(field)
    values = field[:values] && " · values: #{field[:values].join(', ')}#{" (#{field[:values].size} of #{field[:values_total]}; narrow with field and query)" if field[:values_total]}"

    "#{field[:argument]} (#{field[:label]}#{', required' if field[:required]}): #{value}#{values}"
  end

  def field_value_text(field)
    return 'empty' if field[:value].nil?
    return 'free text, below' if free_text?(field)

    Array(field[:value]).join(', ')
  end

  # Free text may come from anyone, the customer too: marked as the ticket's, as get_ticket shows it.
  def free_texts(fields)
    fields.select { |field| free_text?(field) && !field[:value].nil? }.map do |field|
      AI::PromptText.marked_text(field[:value], source: 'ticket', field: fields_by_argument[field[:argument]].name)
    end
  end

  def free_text?(field)
    fields_by_argument[field[:argument]].type.free_text?
  end
end
