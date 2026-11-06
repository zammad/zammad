# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Links two tickets as the ticket view does: the named ticket gets the link and needs change access, the other
#   ticket needs read access, and the kind says what the other ticket is to the named one, in get_ticket's words, so
#   that get_ticket reads the link back as it was asked for. Two tickets are linked once: a second link, in either
#   direction or of another kind, is refused with the kind the link has.
class Service::AI::Tool::LinkTickets < Service::AI::Tool
  OTHER_PREFIX = 'other_'.freeze

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable Zammad/DetectTranslatableString
  KINDS = Service::AI::Tool::GetTicket::LINK_ORDER

  # As a sentence of the result names the link; get_ticket's LINK_WORDS name it from the ticket's side.
  SENTENCE_WORDS = {
    'parent' => 'the parent of',
    'normal' => 'linked to',
    'child'  => 'a child of',
  }.freeze

  description 'Link two tickets of Zammad, as the ticket view does. Name the ticket that gets the link by its ' \
              'ticket_number, ticket_id or ticket_url, and the other ticket by other_ticket_number, other_ticket_id or ' \
              'other_ticket_url. link says what the other ticket is to the named one, as get_ticket names its links: ' \
              "#{KINDS.map { |kind| "#{kind} (#{Service::AI::Tool::GetTicket::LINK_WORDS.fetch(kind)})" }.to_sentence(last_word_connector: ' or ')}. " \
              'Two tickets are linked once; a link is neither changed nor removed here — the user does that in Zammad.'
  title 'Link tickets'
  output_schema(
    type:       'object',
    properties: {
      ticket:        Service::AI::Tool::Output::TicketReference::SCHEMA.merge(description: 'The ticket that got the link.'),
      other_ticket:  Service::AI::Tool::Output::TicketReference::SCHEMA.merge(description: 'The ticket it is linked to.'),
      link:          { type: 'string', enum: KINDS, description: 'What the other ticket is to the ticket.' },
      linked_before: { type: 'boolean', description: 'The two were linked already; nothing changed, and link is the kind they have.' },
    },
    required:   %w[ticket other_ticket link linked_before],
  )
  # rubocop:enable Zammad/DetectTranslatableString
  effect      :write
  permission  'ticket.agent'
  offered_in  :mcp
  audiences   :human_agents
  # A link is added, never removed, and a second call links nothing more.
  mcp_annotations destructive_hint: false, open_world_hint: false, idempotent_hint: true

  # As the other writes: the ticket's customer who is no agent of its group passes follow_up?, not this.
  loads :ticket, type: ::Ticket, pundit_method: :agent_update_access?, named: true

  Service::AI::Tool::Locator::Ticket::PARAMETERS.each do |name, spec|
    parameter "#{OTHER_PREFIX}#{name}", **spec, description: "The other ticket: #{spec[:description].sub(%r{\AThe }, 'the ')}"
  end
  parameter :link, type: :string, enum: KINDS, required: true,
                   description: 'What the other ticket is to the named one: parent, normal or child.' # rubocop:disable Zammad/DetectTranslatableString

  def execute
    invalid = invalid_other_ticket
    return Service::AI::Tool::Runtime::Result.error('invalid_arguments', invalid) if invalid

    # The pair's lock, not the ticket's: a call linking the two the other way round locks the same pair first.
    Service::Link::Add.locking_pair(other_ticket, ticket) do
      # Asks nothing, as for a tag or a note, but answers a cancelled or stale request as every write does.
      response = confirmation&.call(required: false, preview:, snapshot: { ticket_id: ticket.id, other_ticket_id: other_ticket.id, link: })
      next response if response

      result(existing: link_or_existing)
    end
  end

  private

  def link
    argument(:link)
  end

  # The other ticket's arguments under the names the ticket locator reads.
  def other_arguments
    @other_arguments ||= Service::AI::Tool::Locator::Ticket::PARAMETERS.keys.index_with { |name| arguments["#{OTHER_PREFIX}#{name}"] }.compact
  end

  # The ticket locator's own texts, for the other ticket's parameters.
  def other_text(text)
    text.gsub('ticket_', "#{OTHER_PREFIX}ticket_")
  end

  def invalid_other_ticket
    locator = Service::AI::Tool::Locator::Ticket
    return other_text(locator::NO_NAME) if !locator.named?(other_arguments)

    errors = locator.argument_errors(other_arguments)
    return other_text(errors.first) if errors.any?

    'Name two different tickets: a ticket is not linked to itself.' if other_ticket.id == ticket.id # rubocop:disable Zammad/DetectTranslatableString
  end

  # Found and read as the named ticket is, with read access: a missing ticket and one the user may not read are the same
  #   not found, for either ticket.
  def other_ticket
    @other_ticket ||= Gql::ZammadSchema.authorized_object_from_id(
      named_object_gid({ locator: Service::AI::Tool::Locator::Ticket, type: ::Ticket }, other_arguments),
      type: ::Ticket, user: current_user, query: Service::AI::Tool::Locator::Ticket::READ_ACCESS
    )
  end

  # @return [String, nil] the kind the two were linked as already, nil where they are linked now
  def link_or_existing
    Service::Link::Add.execute(source: other_ticket, target: ticket, type: link)
    nil
  rescue Service::Link::Add::LinkedAlready => e
    e.type
  end

  def preview
    "Link ticket #{other_ticket.number} as #{SENTENCE_WORDS.fetch(link)} ticket #{ticket.number}?"
  end

  def result(existing:)
    kind = existing || link
    text = if existing
             "Ticket #{other_ticket.number} is #{SENTENCE_WORDS.fetch(kind)} ticket #{ticket.number} already; nothing was changed. A link is " \
               'changed or removed in Zammad.'
           else
             "Ticket #{other_ticket.number} is now #{SENTENCE_WORDS.fetch(kind)} ticket #{ticket.number}."
           end

    references = { ticket:, other_ticket: }.transform_values { |object| Service::AI::Tool::Output::TicketReference.of(object) }
    Service::AI::Tool::Runtime::Result.ok({ **references, link: kind, linked_before: !existing.nil? }, text:)
  end
end
