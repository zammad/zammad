# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Adds and removes a ticket's references to GitHub and GitLab issues and i-doit objects, as the ticket view does: the
#   references it names, never the whole list, so that one a colleague added since the client read the ticket stays.
#   A reference to add is looked up in its system first, outside the ticket's lock, so that a slow system holds no
#   ticket; what the system refuses is named and the rest is saved.
class Service::AI::Tool::SetTicketReferences < Service::AI::Tool
  MAX_REFERENCES = 10

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable Zammad/DetectTranslatableString
  REFERENCE = {
    type:       'object',
    properties: {
      system: { type: 'string', enum: System.names },
      value:  { type: 'string', description: 'A GitHub or GitLab issue by its link; an i-doit object by its ID.' },
    },
    required:   %w[system value],
  }.freeze

  REFERENCE_OUTPUT = { type: 'object', properties: { system: { type: 'string' }, value: {} }, required: %w[system value] }.freeze

  description 'Link a ticket to GitHub issues, GitLab issues and i-doit objects, and remove such links, as the ticket ' \
              'view does. Name only the references to add or remove; the others stay. Name a GitHub or GitLab issue ' \
              'by its link and an i-doit object by its ID, as those systems show them; this tool does not search ' \
              'them. Each reference to add is checked in its system; one it does not find is named and not added, ' \
              'the others are saved. Only the integrations switched on in Zammad can be used. get_ticket shows the ' \
              'references a ticket has.'
  title 'Set ticket references'
  parameter :add, type: :array, items: REFERENCE, description: 'References to add.'
  parameter :remove, type: :array, items: REFERENCE, description: 'References to remove, as get_ticket shows them.'
  output_schema(
    type:       'object',
    properties: {
      ticket_id:       { type: 'integer' },
      ticket_number:   { type: 'string' },
      url:             { type: 'string', description: 'A link to the ticket in Zammad.' },
      added:           { type: 'array', items: REFERENCE_OUTPUT },
      removed:         { type: 'array', items: REFERENCE_OUTPUT },
      already_present: { type: 'array', items: REFERENCE_OUTPUT, description: 'References to add the ticket had already.' },
      not_present:     { type: 'array', items: REFERENCE_OUTPUT, description: 'References to remove the ticket did not have.' },
      refused:         {
        type:        'array',
        description: 'References to add their system did not find, or did not answer for.',
        items:       { type: 'object', properties: { system: { type: 'string' }, value: { type: 'string' }, reason: { type: 'string' } }, required: %w[system value reason] },
      },
      references:      { type: 'object', description: 'The ticket\'s references afterwards, by system.', additionalProperties: { type: 'array' } },
    },
    required:   %w[ticket_id ticket_number url added removed already_present not_present refused references],
  )
  # rubocop:enable Zammad/DetectTranslatableString
  effect      :write
  permission  'ticket.agent'
  offered_in  :mcp
  audiences   :human_agents
  # It removes references, a second call with the same ones changes nothing more, and it asks the systems outside Zammad.
  mcp_annotations destructive_hint: true, open_world_hint: true, idempotent_hint: true

  # As the other writes: the ticket's customer who is no agent of its group passes follow_up?, not this.
  loads :ticket, type: ::Ticket, pundit_method: :agent_update_access?, named: true

  def self.available?
    System.active.any?
  end

  def execute
    invalid = invalid_references
    return Service::AI::Tool::Runtime::Result.error('invalid_arguments', invalid) if invalid

    found, refused = look_up(entries(:add))
    changes        = ticket.with_lock do
      authorize_change!
      change(found)
    end

    receipt(**changes, refused:)
  end

  private

  # @return [Array<Array(Class, String)>] each reference as its system and the value the caller gave
  def entries(name)
    Array(argument(name)).map { |entry| [System.named(entry['system'].to_s), entry['value'].to_s.strip] }
  end

  # rubocop:disable Zammad/DetectTranslatableString

  def invalid_references
    given = Array(argument(:add)) + Array(argument(:remove))
    return 'Name at least one reference to add or to remove.' if given.empty?
    return "Name at most #{MAX_REFERENCES} references to add and #{MAX_REFERENCES} to remove." if [argument(:add), argument(:remove)].any? { |list| Array(list).size > MAX_REFERENCES }

    given.lazy.filter_map { |entry| entry_error(entry) }.first
  end

  def entry_error(entry)
    system = System.named(entry['system'].to_s)
    return "system \"#{entry['system']}\" is none of #{System.names.join(', ')}." if system.nil?
    return "#{system.label} is not switched on in Zammad. References can be set to: #{System.active.map(&:label).join(', ')}." if !system.active?

    return "A reference to #{system.label} has no value." if entry['value'].to_s.strip.empty?

    system.value_error(entry['value'])
  end

  # rubocop:enable Zammad/DetectTranslatableString

  # @return [Array(Array, Array)] the references found, as their system and stored value, and those refused
  def look_up(additions)
    found   = []
    refused = []

    additions.each do |system, value|
      found << [system, system.resolve(value)]
    rescue System::Refusal => e
      refused << { system: system.system_name, value:, reason: e.message, code: e.code }
    end

    [found.uniq, refused]
  end

  # The lookups ask other systems first, meanwhile the ticket may have moved to a group the user may not change.
  def authorize_change!
    policy = TicketPolicy.new(current_user, ticket)
    return if policy.agent_update_access?
    raise Service::AI::Tool::ReadOnlyError, Service::AI::Tool::Locator::Ticket::READ_ONLY if policy.agent_read_access?

    raise Pundit::NotAuthorizedError
  end

  def change(found)
    changes = { added: [], removed: [], already_present: [], not_present: [] }
    stored  = Hash.new { |hash, system| hash[system] = system.stored(ticket) }

    add(found, stored, changes)
    remove(entries(:remove), stored, changes)
    save(stored) if changes[:added].any? || changes[:removed].any?

    changes.transform_values { |pairs| pairs.map { |system, value| { system: system.system_name, value: } } }
  end

  # A reference the ticket holds in another spelling counts as present, as it does for a removal.
  def add(found, stored, changes)
    found.each do |system, value|
      present = system.stored_match(stored[system], value)
      changes[present.nil? ? :added : :already_present] << [system, present || value]
      stored[system] += [value] if present.nil?
    end
  end

  def remove(removals, stored, changes)
    removals.each do |system, value|
      match = system.stored_match(stored[system], value)
      changes[match.nil? ? :not_present : :removed] << [system, match || value]
      stored[system] -= [match] if match
    end
  end

  def save(stored)
    stored.each { |system, values| system.store(ticket, values) }
    ticket.save!
  end

  def receipt(refused:, **changes)
    content = {
      ticket_id:     ticket.id,
      ticket_number: ticket.number,
      url:           Service::AI::Tool::ObjectLink.url(type: 'Ticket', id: ticket.id),
      **changes,
      refused:       refused.map { |reference| reference.except(:code) },
      references:    Service::Ticket::ExternalReferences::List.execute(ticket:) || {},
    }

    return Service::AI::Tool::Runtime::Result.error(refusal_code(refused), text(content)) if refused.any? && changes[:added].empty? && changes[:removed].empty?

    Service::AI::Tool::Runtime::Result.ok(content, text: text(content))
  end

  # One system that did not answer makes the whole call one to try again later.
  def refusal_code(refused)
    codes = refused.pluck(:code).uniq
    return 'unavailable' if codes.include?('unavailable')

    codes.one? ? codes.first : 'not_found'
  end

  # rubocop:disable Zammad/DetectTranslatableString

  def text(content)
    lines = { added: 'Added', removed: 'Removed', already_present: 'Already linked', not_present: 'Not linked, so not removed' }
      .filter_map { |key, label| "#{label}: #{content[key].map { |reference| reference_text(reference) }.join(', ')}." if content[key].any? }
    refused = content[:refused].map { |reference| "Not added: #{reference_text(reference)}: #{reference[:reason]}" }

    ["Ticket #{content[:ticket_number]}:", *lines, *refused, "References now: #{references_text(content[:references])}."].join("\n")
  end

  def reference_text(reference)
    "#{System.named(reference[:system]).noun} #{reference[:value]}"
  end

  # rubocop:enable Zammad/DetectTranslatableString

  def references_text(references)
    shown = references.flat_map { |name, values| values.map { |value| reference_text({ system: name.to_s, value: }) } }

    shown.presence&.join(', ') || 'none'
  end
end
