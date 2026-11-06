# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Creates a ticket as the REST API and GraphQL do: as the user, through the service the new interface uses, in a group
#   the user may create tickets in, for a customer who exists, with a phone call, an email or an internal note as its
#   first message. Values are given by name and matched against what the create form offers; before anything is saved,
#   Core Workflow's create screen says what it allows and still needs. What the customer can read is saved only once the
#   user confirmed it, as for an article, and the question asks for missing values in the same form where it can.
class Service::AI::Tool::CreateTicket < Service::AI::Tool
  include Service::AI::Tool::Concerns::ArticleParameters

  # The ticket's own fields that are arguments of their own; custom fields go into the fields object.
  ARGUMENTS = %w[customer title group state priority owner pending_time].freeze

  # How the first message reads in Zammad: the article type, who wrote it and whether the customer can read it.
  MESSAGES = {
    'phone_in'  => { type: 'phone', sender: 'Customer', internal: false },
    'phone_out' => { type: 'phone', sender: 'Agent', internal: false },
    'email'     => { type: 'email', sender: 'Agent', internal: false },
    'note'      => { type: 'note', sender: 'Agent', internal: true },
  }.freeze

  # The create form's types, as the settings name them; the internal note is the tool's own, offered always.
  FORM_TYPES = { 'phone-in' => 'phone_in', 'phone-out' => 'phone_out', 'email-out' => 'email' }.freeze

  Invalid = Service::AI::Tool::Fields::EntityAttribute::Invalid
  InvalidArticle = Service::AI::Tool::CreateArticle::Preparation::InvalidArticle

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable-next Zammad/DetectTranslatableString
  OUTPUT_SCHEMA = {
    type:       'object',
    properties: {
      ticket_id:     { type: 'integer' },
      ticket_number: { type: 'string' },
      ticket:        Service::AI::Tool::Output::Ticket.schema.merge(description: 'The new ticket. Missing where the user may not read it.'),
      article_id:    { type: 'integer', description: 'The first message.' },
      message:       { enum: MESSAGES.keys },
      outcome:       { enum: %w[saved queued], description: 'queued: the email is on its way to the customer.' },
      url:           { type: 'string', description: 'A link to the ticket in Zammad.' },
    },
    required:   %w[ticket_id ticket_number article_id message outcome url],
  }.freeze

  # rubocop:disable Zammad/DetectTranslatableString
  description 'Create a ticket, as the ticket form in Zammad does: for a customer who exists, in a group you may create ' \
              'tickets in, with a title and a first message — a phone call received (phone_in) or placed ' \
              '(phone_out), an email sent to the customer, or an internal note. Zammad cannot write the first message in a ' \
              'chat, a web form, WhatsApp, Telegram, SMS or Facebook: only the customer does, and create_article ' \
              'answers there only in a ticket the customer started that way. For such a request, tell ' \
              'the user so and offer a phone call or an email. A request the customer made is phone_in, ' \
              'unless the user names another way; note is for the agents\' own work no customer asked for, such as a ' \
              'reminder or an internal appointment. Give values by name: the customer ' \
              'by email, login, whole name or "ID 5" — a person, not an organization —, the group by its whole name ' \
              'or last level, custom fields by label in fields. A name that fits nobody or several, or a person or a group only by ' \
              'a part, names the candidates for the user to confirm; a customer who ' \
              'does not exist yet has to be created in Zammad first. get_ticket_fields without a ticket lists the ' \
              'fields and values of a new ticket. Where supported the client confirms what the customer can read, otherwise ' \
              'use client tool approval. Attachments are unsupported. Do not retry an uncertain write automatically.'
  title 'Create ticket'
  parameter :customer, type: :string, required: true, description: 'The customer, a person: by email, login, whole name or "ID 5". For the agents\' own work, the user; a colleague to work on it is the owner.'
  parameter :title, type: :string, required: true, description: 'The ticket\'s title.'
  parameter :group, type: :string, required: true, description: 'The group, its levels joined by " › " or its last level.'
  parameter :message, type: :string, enum: MESSAGES.keys,
                      description: 'The first message: phone_in for a request the customer made, also by email, phone_out for a call to the customer, email to send a new email to the customer, note for an internal note on the agents\' own work. Otherwise Zammad\'s default for a new ticket, usually phone_in.'
  parameter :text, type: :string, required: true, description: 'The first message, in the format content_type names.'
  content_type_parameter
  parameter :to, type: :array, items: { type: 'string' }, description: 'Email only, required: the recipients, normally the customer\'s email address.'
  parameter :cc, type: :array, items: { type: 'string' }, description: 'Email only: CC recipients the user asked for.'
  parameter :subject, type: :string, description: 'Email only: the subject. Otherwise the title.'
  parameter :include_signature, type: :boolean, default: true, description: 'Email only: append the group\'s signature.'
  parameter :state, type: :string, description: 'The state, such as "open". Otherwise the form\'s default.'
  parameter :priority, type: :string, description: 'The priority, such as "3 high".'
  parameter :owner, type: :string, description: 'An agent by the whole name, email or login, or "me"; one who works in the group, as get_ticket_fields with the group lists them.'
  parameter :pending_time, type: :string, description: 'For a pending state: when it is reached, ISO 8601.'
  parameter :fields, type: :object, description: 'Custom fields by their names as get_ticket_fields lists them, each with its value by label.'
  # rubocop:enable Zammad/DetectTranslatableString
  output_schema OUTPUT_SCHEMA
  effect      :write
  permission  'ticket.agent'
  offered_in  :mcp
  audiences   :human_agents
  # Destructive as create_article: an email or a public message reaches the customer, and a client without forms asks
  #   its user by this hint. A second call creates a second ticket.
  mcp_annotations destructive_hint: true, open_world_hint: true, idempotent_hint: false

  # The user's answer is consumed in the transaction that writes, so that a write that fails gives it back.
  def execute
    check_message
    data     = ticket_data
    prepared = prepare_message(data)

    ActiveRecord::Base.transaction do
      answers = check(data, prepared)
      next answers if answers.is_a?(Service::AI::Tool::Runtime::Result)
      next unread_answer if continuing? && !answered?
      next create(data, prepared) if !answers

      data = data.merge(ticket_data(answers))
      recheck(data) || create_answered(data, prepared, answers)
    end
  rescue Invalid => e
    Service::AI::Tool::Runtime::Result.error(e.code, e.message)
  # Core Workflow's refusal is one of the article service's errors, so it is rescued first.
  rescue Exceptions::ApplicationModel, Pundit::NotAuthorizedError, ActiveRecord::RecordInvalid => e
    refusal(e)
  rescue InvalidArticle, Exceptions::UnprocessableContent => e
    Service::AI::Tool::Runtime::Result.error('invalid_arguments', e.message)
  end

  private

  # The first message: the one asked for, or the create form's default where it offers it, else its first type, as the
  #   form falls back; a type the form does not offer here is refused.
  def message_name
    @message_name ||= argument(:message) || ([FORM_TYPES[Setting.get('ui_ticket_create_default_type')]] & offered_messages).first || offered_messages.first
  end

  def offered_messages
    @offered_messages ||= FORM_TYPES.values_at(*Array(Setting.get('ui_ticket_create_available_types'))).compact + ['note']
  end

  def check_message
    return if offered_messages.include?(message_name)

    raise Invalid.new('invalid_value', "message \"#{message_name}\" is not offered for a new ticket here. Offered: #{offered_messages.join(', ')}.")
  end

  # What the create service takes: the records of the ticket's own fields, the stored values of custom fields.
  def ticket_data(answers = {})
    (requested + answers.to_a).to_h do |argument, value|
      field = form_fields[argument] || unknown_field(argument)

      [field.type.data_key.to_sym, resolve(argument, field, value)]
    end
  end

  def resolve(argument, field, value)
    Service::AI::Tool::Fields::EntityAttribute.resolve(field.type, value)
  rescue Invalid => e
    raise e if argument != 'customer'

    raise organization_named(value) || e
  end

  # An organization names no customer: its members are the candidates, and none of them is picked.
  def organization_named(value)
    scope        = OrganizationPolicy::Scope.new(current_user, ::Organization).resolve
    organization = scope.find_by('LOWER(organizations.name) = ?', value.to_s.squish.downcase)
    return if organization.nil?

    members = UserPolicy::Scope.new(current_user, ::User).resolve.where(id: organization.all_members.select(:id))
    shown   = members.reorder(:id).limit(Service::AI::Tool::Fields::EntityAttribute::CANDIDATES).map { |member| Service::AI::Tool::Fields::EntityAttribute.user_description(member) }
    more    = members.count - shown.size

    Invalid.new('ambiguous', "customer \"#{value}\" is an organization; name one of its members as the customer: #{shown.presence&.join(', ') || 'none you may see'}#{", and #{more} more" if more.positive?}.")
  end

  # A new ticket as the create form starts it: in the state and with the priority a new ticket gets.
  def new_ticket
    @new_ticket ||= ::Ticket.new(state: ::Ticket::State.find_by(default_create: true), priority: ::Ticket::Priority.find_by(default_create: true))
  end

  def requested
    @requested ||= begin
      own    = ARGUMENTS.filter_map { |name| [name, argument(name)] if !argument(name).nil? }
      custom = (argument(:fields) || {}).map { |name, value| ["fields.#{name}", value] }

      own + custom
    end
  end

  # The fields of a new ticket the user may set, by the argument that sets them; Core Workflow is asked by #check.
  def form_fields
    @form_fields ||= Service::AI::Tool::Fields::TicketFields.settable(ticket: ::Ticket.new, user: current_user, rules: false)
  end

  def unknown_field(argument)
    custom = form_fields.keys.select { |key| key.start_with?('fields.') }.map { |key| key.delete_prefix('fields.') }

    raise Invalid.new('invalid_value', "#{argument.delete_prefix('fields.')} is no field of a new ticket you may set. Custom fields: #{custom.presence&.join(', ') || 'none'}.") if argument.start_with?('fields.')

    raise Invalid.new('not_settable', "#{argument} cannot be set on a new ticket.")
  end

  # The first message as create_article prepares one, for the ticket not saved yet: the group's sender and signature, the
  #   recipients the client named.
  def prepare_message(data)
    message = MESSAGES.fetch(message_name)
    draft   = new_ticket.dup.tap { |ticket| ticket.assign_attributes(data.select { |key, _| ticket.respond_to?(:"#{key}=") }) }
    given   = arguments.slice('text', 'content_type', 'to', 'cc', 'subject', 'include_signature').merge('type' => message[:type], 'internal' => message[:internal])

    prepared = Service::AI::Tool::CreateArticle::Preparation.execute(ticket: draft, user: current_user, arguments: given)
    prepared[:article_data][:sender] = message[:sender]
    prepared
  end

  # Before anything is saved: a value the create screen refuses is named; values it still needs and a message the
  #   customer can read go into one question to the user, where the client can ask.
  #
  # @return [Service::AI::Tool::Runtime::Result, Hash, nil] a refusal or the request to the client, the values the user gave by
  #   argument, or nil to go on
  def check(data, prepared)
    changes = stored_changes(data)
    fields  = Service::AI::Tool::Fields::TicketFields.settable(ticket: new_ticket, user: current_user, changes:)
    message = Service::AI::Tool::Fields::TicketFields.not_allowed_text(fields, changes, subject: 'a new ticket in this group')
    return Service::AI::Tool::Runtime::Result.error('not_allowed', message) if message

    missing = Service::AI::Tool::Fields::TicketFields.missing(fields, changes, record: new_ticket)
    ask(data, missing, prepared)
  end

  # A client without a form gets the missing values named, and its own tool approval stands for the confirmation.
  def ask(data, missing, prepared)
    refusal = Service::AI::Tool::Runtime::Result.error('missing_value', Service::AI::Tool::Fields::TicketFields.missing_text(missing, subject: 'A new ticket in this group')) if missing.any?
    form    = Service::AI::Tool::Fields::TicketFields.form_fields(missing, user: current_user) if missing.any?
    return refusal if refusal && (confirmation.nil? || form.nil?)

    # Asked also where nothing needs a confirmation, so that a request cancelled already creates nothing.
    confirm = prepared.fetch(:confirmation)
    answer  = confirmation&.call(
      # The message as create_article binds it, with the channel and adapter an email goes out over.
      snapshot: { arguments: requested, customer_id: data[:customer].id, group_id: data[:group].id, message: message_name, **confirm[:snapshot].slice(:article_data, :context) },
      preview:  preview(data, confirm[:preview], form),
      required: confirm[:required] || missing.any?,
      fields:   form,
      declined: refusal,
    )
    # A confirmation without fields answers nil once accepted.
    @answered = true if !answer.is_a?(Service::AI::Tool::Runtime::Result)
    answer.nil? && refusal ? refusal : answer
  end

  # A call that carries the user's answer creates only once the answer is read: where the question no longer comes up,
  #   as a field became optional meanwhile, nothing is created, so that a "no" never creates a ticket.
  def continuing?
    confirmation.respond_to?(:continuing?) && confirmation.continuing?
  end

  def answered?
    @answered
  end

  def unread_answer
    Service::AI::Tool::Runtime::Result.error('confirmation_required', 'The fields of a new ticket changed since the user was asked, so the answer no longer fits. Nothing was created. Call again to review the ticket.')
  end

  # The answers can make other fields required or refuse a value, as the create screen decides with them; both are named,
  #   as the user was asked once in this call.
  def recheck(data)
    changes = stored_changes(data)
    fields  = Service::AI::Tool::Fields::TicketFields.settable(ticket: new_ticket, user: current_user, changes:)
    message = Service::AI::Tool::Fields::TicketFields.not_allowed_text(fields, changes, subject: 'a new ticket in this group')
    return Service::AI::Tool::Runtime::Result.error('not_allowed', message) if message

    missing = Service::AI::Tool::Fields::TicketFields.missing(fields, changes, record: new_ticket)
    Service::AI::Tool::Runtime::Result.error('missing_value', Service::AI::Tool::Fields::TicketFields.missing_text(missing, subject: 'A new ticket in this group')) if missing.any?
  end

  def preview(data, message, form)
    [
      "Create a ticket \"#{argument(:title)}\" for #{Service::AI::Tool::Fields::EntityAttribute.user_description(data[:customer])} in group #{Service::AI::Tool::Fields::EntityAttribute.group_name(data[:group])}?",
      ("It needs #{form.values.pluck(:title).join(', ')} as well." if form),
      message.sub(%r{\ACreate \S+ on ticket \S*\?}, "First message: #{message_name}."),
    ].compact.join("\n\n")
  end

  # The data as the record stores it, by attribute, as Core Workflow takes it.
  def stored_changes(data)
    data.to_h do |key, value|
      field = form_fields.values.find { |candidate| candidate.type.data_key == key.to_s }

      [field.name, value.is_a?(ActiveRecord::Base) ? value.id : value]
    end
  end

  # The values the user gave can change the first message, as its signature names them: the message the user confirmed
  #   is the one sent, or nothing is created and the client calls again with the values, to confirm the message anew.
  def create_answered(data, prepared, answers)
    answered = prepare_message(data)
    return create(data, answered) if !prepared.dig(:confirmation, :required) || answered[:article_data].slice(:body, :subject) == prepared[:article_data].slice(:body, :subject)

    Service::AI::Tool::Runtime::Result.error('confirmation_required', "The first message changes with the values the user gave, as its signature names them, so it is no longer the message the user confirmed. Nothing was created. Call again with these values to confirm the message as it will be sent: #{given_arguments(answers).to_json}.")
  end

  # The answers by argument, custom fields within fields, as a call takes them.
  def given_arguments(answers)
    answers.each_with_object({}) do |(argument, value), given|
      next given[argument] = value if !argument.start_with?('fields.')

      (given['fields'] ||= {})[argument.delete_prefix('fields.')] = value
    end
  end

  # The ticket and its first message in one transaction of Zammad's, so that triggers and notifications see the ticket
  #   created with its message, as over the REST API.
  def create(data, prepared)
    ticket = Service::Ticket::Create.with_current_user(current_user).execute(ticket_data: data.merge(article: article_data(data, prepared)), prepared_article: true)

    receipt(ticket, ticket.articles.first, queued: prepared.fetch(:outbound))
  end

  # A phone call names who called whom, as the create form fills it in; an email keeps its sender and recipients.
  def article_data(data, prepared)
    article = prepared.fetch(:article_data).dup
    return article if article[:type] != 'phone'

    customer = Channel::EmailBuild.recipient_line(data[:customer].fullname.presence, data[:customer].email)
    group    = data[:group].name
    article[:sender] == 'Customer' ? article.merge(from: customer, to: group) : article.merge(from: group, to: customer)
  end

  def receipt(ticket, article, queued:)
    row     = Service::AI::Tool::Output::Ticket.row(ticket) if readable?(ticket)
    url     = Service::AI::Tool::ObjectLink.url(type: 'Ticket', id: ticket.id)
    content = {
      ticket_id:     ticket.id,
      ticket_number: ticket.number,
      ticket:        row&.content,
      article_id:    article.id,
      message:       message_name,
      outcome:       queued ? 'queued' : 'saved',
      url:,
    }.compact

    text = [row&.text || "Ticket #{ticket.number} (ID #{ticket.id}) · in a group whose tickets you may not read.", AI::PromptText.xml_text("Created with its first message (#{message_name}#{', on its way to the customer' if queued})."), url]

    Service::AI::Tool::Runtime::Result.ok(content, text: text.join("\n"))
  end

  # Zammad refused the ticket after the check: the user may not create in the group, or a rule the check does not
  #   know of.
  def refusal(error)
    Rails.logger.info "AI tool create_ticket refused: #{error.message}"
    Service::AI::Tool::Runtime::Result.error('not_allowed', 'Zammad refused the ticket. Check the values with get_ticket_fields without a ticket.')
  end
end
