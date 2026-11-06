# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Changes a ticket's state, priority, group, owner, pending time and custom fields as the REST API and GraphQL do: as the
#   user, through the update service the UI uses, so that Core Workflow checks the change on save and the ticket's
#   validators run as for the form. Values are given by name and matched against what the user may choose; only when
#   Zammad refuses the change does the tool ask Core Workflow what the ticket allows or needs, to name it.
class Service::AI::Tool::UpdateTicket < Service::AI::Tool
  include Service::AI::Tool::Concerns::ConfirmationArgument

  # The ticket's own fields that are arguments of their own; custom fields go into the fields object.
  ARGUMENTS = %w[state priority group owner pending_time].freeze

  Invalid = Service::AI::Tool::Fields::EntityAttribute::Invalid

  CHECKLIST_ITEMS       = 5
  CHECKLIST_ITEM_LENGTH = 100

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable-next Zammad/DetectTranslatableString
  OUTPUT_SCHEMA = {
    type:       'object',
    properties: {
      ticket_id:     { type: 'integer' },
      ticket_number: { type: 'string' },
      ticket:        Service::AI::Tool::Output::Ticket.schema.merge(description: 'The ticket after the change. Missing where the user may no longer read it.'),
      changes:       {
        type:        'array',
        description: 'Every field that changed, also one Zammad changed with it, such as an owner who cannot work in the new group.',
        items:       {
          type:       'object',
          properties: {
            argument: { type: 'string' },
            label:    { type: 'string' },
            from:     { description: 'The value before, by name or label. Missing where it was empty.' },
            to:       { description: 'The value now, by name or label. Missing where it is empty.' },
          },
          required:   %w[argument label],
        },
      },
      not_applied:   {
        type:        'array',
        description: 'What was asked for and Zammad saved otherwise, as it does over the REST API: an owner who may not own tickets of the group becomes nobody.',
        items:       {
          type:       'object',
          properties: {
            argument: { type: 'string' },
            label:    { type: 'string' },
            asked:    {},
            now:      {},
            allowed:  { type: 'array', items: { type: 'string' }, description: 'The values the ticket allows now, by name or label, the first 20.' },
          },
          required:   %w[argument label],
        },
      },
      url:           { type: 'string', description: 'A link to the ticket in Zammad.' },
    },
    required:   %w[ticket_id ticket_number changes url],
  }.freeze

  # rubocop:disable Zammad/DetectTranslatableString
  description 'Change a ticket\'s state, priority, group, owner, pending time or custom fields, as the ticket form in ' \
              'Zammad does. Give values by name, as get_ticket shows them: state "closed", owner "me", an agent\'s ' \
              'email or "nobody", group "2nd Level", a custom field\'s option by its label in fields. No lookup is ' \
              'needed first: a name that fits no value or several names the valid ones or the candidates. A person ' \
              'or a group is taken by the whole name, a person also by email or ID: a part of the name names the ' \
              'candidate instead, for the user to confirm. A pending state needs pending_time. To reply and change ' \
              'the state, call create_article first, then this tool.'
  title 'Update ticket'
  parameter :state, type: :string, description: 'The state, such as "open", "closed" or "pending reminder".'
  parameter :priority, type: :string, description: 'The priority, such as "3 high".'
  parameter :group, type: :string, description: 'The group to move the ticket to, its levels joined by " › " or its last level.'
  parameter :owner, type: :string, description: 'An agent by the whole name, email or login, "me", or "nobody".'
  parameter :pending_time, type: :string, description: 'For a pending state: when it is reached, ISO 8601 such as "2026-10-26T09:00:00+02:00".'
  parameter :fields, type: :object, description: 'Custom fields by their names as get_ticket shows them, each with its value by label; null empties one.'
  confirmation_argument :close_with_open_checklist, action: 'close the ticket with its checklist incomplete'
  # rubocop:enable Zammad/DetectTranslatableString
  output_schema OUTPUT_SCHEMA
  effect      :write
  permission  'ticket.agent'
  offered_in  :mcp
  audiences   :human_agents
  # It overwrites values, and a second call with the same values changes nothing more.
  mcp_annotations destructive_hint: true, open_world_hint: false, idempotent_hint: true

  # As the note and the article tools: the ticket's customer who is no agent of its group passes follow_up?, not this.
  loads :ticket, type: ::Ticket, pundit_method: :agent_update_access?, named: true

  def execute
    return Service::AI::Tool::Runtime::Result.error('invalid_arguments', 'Name at least one field to change.') if requested.empty?

    # Asking and writing in one transaction: a write that fails gives the user's answer back.
    ticket.with_lock do
      before = values
      change || receipt(before)
    end
  rescue Invalid => e
    Service::AI::Tool::Runtime::Result.error(e.code, e.message)
  rescue Service::Ticket::Update::Validator::BaseError => e
    Service::AI::Tool::Runtime::Result.error('not_allowed', e.message)
  end

  private

  attr_reader :saved

  # Saves the change. Where Zammad needs what only the user can give — a value Core Workflow requires, or the yes the
  #   form asks for before closing with an open checklist —, a client that can shows its user a form, and the change is
  #   saved again with the answer, once per call; elsewhere the error names what is needed, and the yes comes in the
  #   conversation, with close_with_open_checklist.
  #
  # @param answers [Hash{String => Object}] the user's answers, by argument
  # @return [Service::AI::Tool::Runtime::Result, nil] nil once saved
  def change(answers = {}, close_confirmed: false)
    data = ticket_data(answers)
    skip = [Service::Ticket::Update::Validator::ChecklistCompleted] if close_confirmed

    return unread_answer if !save(data, skip)

    @saved = data
    nil
  rescue Exceptions::ApplicationModel => e
    refused_change(e, data, answers, close_confirmed:)
  rescue Service::Ticket::Update::Validator::ChecklistCompleted::Error
    return change(answers, close_confirmed: true) if confirmed_by_argument?(:close_with_open_checklist)

    given = ask(**checklist_request, declined: checklist_refusal)
    return given if given.is_a?(Service::AI::Tool::Runtime::Result)
    return checklist_refusal if given.nil?

    change(answers, close_confirmed: true)
  end

  # A call that carries the user's answer saves only once the answer is read: where the question no longer comes up, as
  #   a colleague completed the checklist meanwhile, the save is undone, so that a "no" never closes the ticket.
  #
  # @return [Boolean] whether the change was saved
  def save(data, skip)
    ActiveRecord::Base.transaction(requires_new: true) do
      # The service adds the screen to the data it gets; the tool keeps its own to explain a refusal.
      Service::Ticket::Update.with_current_user(current_user).execute(ticket:, ticket_data: data.dup, skip_validators: skip)
      raise ActiveRecord::Rollback if continuing? && !answered?

      true
    end.present?
  end

  def continuing?
    confirmation.respond_to?(:continuing?) && confirmation.continuing?
  end

  def unread_answer
    ticket.reload

    Service::AI::Tool::Runtime::Result.error('confirmation_required', 'The ticket changed since the user was asked, so the answer no longer fits. Nothing was changed. Call again to review the change.')
  end

  # Core Workflow refused the change: the fields as the change leaves them name what they allow, or what they still need.
  def refused_change(error, data, answers, close_confirmed:)
    ticket.reload
    changes = stored_changes(data)
    fields  = Service::AI::Tool::Fields::TicketFields.settable(ticket:, user: current_user, changes:)
    message = Service::AI::Tool::Fields::TicketFields.not_allowed_text(fields, changes, subject: 'this ticket')
    return Service::AI::Tool::Runtime::Result.error('not_allowed', message) if message

    missing = Service::AI::Tool::Fields::TicketFields.missing(fields, changes, record: ticket)
    return unexplained_refusal(error) if missing.empty?

    request = missing_request(missing)
    refusal = Service::AI::Tool::Runtime::Result.error('missing_value', Service::AI::Tool::Fields::TicketFields.missing_text(missing, subject: 'This change'))
    given   = request && ask(**request, declined: refusal)
    return given if given.is_a?(Service::AI::Tool::Runtime::Result)
    return refusal if given.nil?

    change(answers.merge(given), close_confirmed:)
  end

  # Asks the client's user, once per call; a user who declines gets what the client would get without a form.
  #
  # @return [Service::AI::Tool::Runtime::Result, Hash, nil] the request to the client or a refusal, the answers, or nil where the
  #   client cannot ask
  def ask(fields:, preview:, declined:)
    return if confirmation.nil? || answered?

    answer = confirmation.call(snapshot: { ticket_id: ticket.id, arguments: requested, values: }, preview:, required: true, fields:, declined:)
    @answered = true if answer.is_a?(Hash)
    answer
  end

  def answered?
    @answered
  end

  # The fields the user may set on the ticket, by the argument that sets them; Core Workflow decides on save.
  def form_fields
    @form_fields ||= Service::AI::Tool::Fields::TicketFields.settable(ticket:, user: current_user, rules: false)
  end

  # What the update service takes: the records of the ticket's own fields, the stored values of custom fields.
  def ticket_data(answers = {})
    (requested + answers.to_a).to_h do |argument, value|
      field = form_fields[argument] || unknown_field(argument)

      [field.type.data_key.to_sym, Service::AI::Tool::Fields::EntityAttribute.resolve(field.type, value)]
    end
  end

  def requested
    @requested ||= begin
      own    = ARGUMENTS.filter_map { |name| [name, argument(name)] if !argument(name).nil? }
      custom = (argument(:fields) || {}).map { |name, value| ["fields.#{name}", value] }

      own + custom
    end
  end

  def unknown_field(argument)
    custom = form_fields.keys.select { |key| key.start_with?('fields.') }.map { |key| key.delete_prefix('fields.') }

    raise Invalid.new('invalid_value', "#{argument.delete_prefix('fields.')} is no field you may set on this ticket. Custom fields: #{custom.presence&.join(', ') || 'none'}.") if argument.start_with?('fields.')

    raise Invalid.new('not_settable', "#{argument} cannot be set on this ticket. Change it in Zammad.")
  end

  # Every field by the label of its value, to tell what changed.
  def values
    form_fields.transform_values { |field| Service::AI::Tool::Fields::EntityAttribute.value_text(field, ticket[field.name]) }
  end

  def unexplained_refusal(error)
    Rails.logger.info "AI tool update_ticket refused: #{error.message}"
    Service::AI::Tool::Runtime::Result.error('not_allowed', 'Zammad refused the change. Check the values with get_ticket_fields.')
  end

  # The data as the record stores it, by attribute, as Core Workflow takes it.
  def stored_changes(data)
    data.to_h do |key, value|
      field = form_fields.values.find { |candidate| candidate.type.data_key == key.to_s }

      [field.name, value.is_a?(ActiveRecord::Base) ? value.id : value]
    end
  end

  # The form that asks for the missing values; nil where a form cannot ask for one of them.
  def missing_request(missing)
    fields = Service::AI::Tool::Fields::TicketFields.form_fields(missing, user: current_user)
    return if fields.nil?

    { fields:, preview: "Ticket #{ticket.number}: this change needs #{fields.values.pluck(:title).join(', ')} as well." }
  end

  def checklist_request
    {
      fields:  {},
      preview: "Ticket #{ticket.number}: #{open_checklist_text}. Close the ticket anyway?",
    }
  end

  # Agents write the items, so they come as marked texts after the error.
  def checklist_refusal
    items = open_checklist_items

    Service::AI::Tool::Runtime::Result.error(
      'checklist_incomplete',
      "The ticket's checklist has #{items.size} open #{'item'.pluralize(items.size)}, below. Zammad closes a ticket " \
      "with an incomplete checklist only once the agent confirms it. #{confirmation_argument_hint(:close_with_open_checklist, action: 'close it anyway') || 'Tell the user.'}",
      texts: shown_items(items).map { |text| AI::PromptText.marked_text(text, source: 'agent', field: 'checklist_item') },
    )
  end

  # For the form the client shows its user: a person reads it, so the items come plainly.
  def open_checklist_text
    items = open_checklist_items

    "checklist has #{items.size} open #{'item'.pluralize(items.size)}: #{shown_items(items).join('; ')}"
  end

  def open_checklist_items
    ticket.reload.checklist&.items&.incomplete&.reorder(:id)&.pluck(:text) || []
  end

  def shown_items(items)
    shown = items.first(CHECKLIST_ITEMS).map { |text| text.to_s.squish.truncate(CHECKLIST_ITEM_LENGTH) }

    items.size > CHECKLIST_ITEMS ? [*shown, "… and #{items.size - CHECKLIST_ITEMS} more"] : shown
  end

  def receipt(before)
    after   = values
    changes = form_fields.filter_map do |argument, field|
      next if before[argument] == after[argument]

      { argument:, label: field.attribute.display, from: before[argument], to: after[argument] }.compact
    end

    readable = readable?(ticket)
    row      = Service::AI::Tool::Output::Ticket.row(ticket) if readable
    skipped  = not_applied(after)
    content  = { ticket_id: ticket.id, ticket_number: ticket.number, ticket: row&.content, changes:, not_applied: skipped.presence, url: }.compact

    Service::AI::Tool::Runtime::Result.ok(content, text: receipt_text(row, changes, skipped))
  end

  # What was asked for and is not on the ticket now: Zammad saves some values otherwise than given, as the REST API
  #   does — an owner who may not own tickets of the group becomes nobody, a pending time without a pending state empty.
  def not_applied(after)
    saved.filter_map do |key, value|
      argument, field = form_fields.find { |_candidate, candidate| candidate.type.data_key == key.to_s }
      asked = Service::AI::Tool::Fields::EntityAttribute.value_text(field, value.is_a?(ActiveRecord::Base) ? value.id : value)
      next if asked == after[argument]

      { argument:, label: field.attribute.display, asked:, now: after[argument], allowed: allowed_now(argument) }.compact
    end
  end

  def fields_now
    @fields_now ||= Service::AI::Tool::Fields::TicketFields.settable(ticket:, user: current_user)
  end

  # What the form would offer instead, so the client can name it without asking again.
  def allowed_now(argument)
    field = fields_now[argument]

    field && Service::AI::Tool::Fields::EntityAttribute.values(field)&.first(Service::AI::Tool::Fields::EntityAttribute::VALID_VALUES)
  end

  # rubocop:disable Zammad/DetectTranslatableString
  def receipt_text(row, changes, skipped)
    changed = changes.map { |change| change_text(change) }

    [
      row&.text || "Ticket #{ticket.number} (ID #{ticket.id}) · now in a group whose tickets you may not read.",
      AI::PromptText.xml_text(changed.any? ? "Changed: #{changed.join(' · ')}" : 'Nothing changed: the ticket already had these values.'),
      (AI::PromptText.xml_text("Not applied, as Zammad saved it otherwise: #{skipped.map { |item| skipped_text(item) }.join(' · ')}") if skipped.any?),
      *changes.select { |change| free_text?(change) }.flat_map { |change| free_texts(change) },
      url,
    ].compact.join("\n")
  end

  def skipped_text(item)
    return item[:argument] if free_text?(item)

    "#{item[:argument]} (asked #{item.fetch(:asked, 'empty')}, now #{item.fetch(:now, 'empty')}#{"; allowed: #{item[:allowed].join(', ')}" if item[:allowed]})"
  end

  def change_text(change)
    return "#{change[:argument]}: changed, the texts below" if free_text?(change)

    "#{change[:argument]}: #{change.fetch(:from, 'empty')} → #{change.fetch(:to, 'empty')}"
  end
  # rubocop:enable Zammad/DetectTranslatableString

  # Free text may come from anyone, the customer too: marked as the ticket's, as get_ticket shows it.
  def free_texts(change)
    name = form_fields[change[:argument]].name

    { 'before' => change[:from], 'after' => change[:to] }.filter_map do |version, text|
      AI::PromptText.marked_text(text, source: 'ticket', field: name, version:) if !text.nil?
    end
  end

  def free_text?(change)
    form_fields[change[:argument]].type.free_text?
  end

  def url
    Service::AI::Tool::ObjectLink.url(type: 'Ticket', id: ticket.id)
  end
end
