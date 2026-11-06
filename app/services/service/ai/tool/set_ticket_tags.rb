# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Adds and removes tags of a ticket as the REST API does, as the user: the tags it names, never the whole list, so that
#   a tag a colleague or a trigger added since the client read the ticket stays. Tags are a vocabulary the team keeps:
#   a name is matched to an existing tag without regard to case, and only that whole name — a tag whose name merely
#   contains it is another tag, so it is named as a candidate, not taken. A new tag is created only when the call asks
#   for it and the user may create tags, as the tag field of the interface creates one only for a name typed on purpose.
class Service::AI::Tool::SetTicketTags < Service::AI::Tool
  MAX_NAMES  = 20
  CANDIDATES = 5

  Invalid = Service::AI::Tool::Fields::EntityAttribute::Invalid

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable Zammad/DetectTranslatableString
  description 'Add tags to a ticket and remove tags from it, by name. Name only the tags to add or remove; the others ' \
              'stay. Names are matched to the existing tags without regard to case; a name that matches none adds ' \
              'nothing and the answer names the closest tags, so ask the user which one they mean. Set ' \
              'create_new_tags only when the user asked for a new tag; Zammad creates it only where the user may. ' \
              'list_tags lists the tags there are.'
  title 'Set ticket tags'
  parameter :add, type: :array, items: { type: 'string' }, description: 'Tags to add, by name.'
  parameter :remove, type: :array, items: { type: 'string' }, description: 'Tags to remove, by name.'
  parameter :create_new_tags, type: :boolean, default: false, description: 'Create the tags to add that do not exist yet. Only when the user asked for a new tag.'
  output_schema(
    type:       'object',
    properties: {
      ticket_id:     { type: 'integer' },
      ticket_number: { type: 'string' },
      url:           { type: 'string', description: 'A link to the ticket in Zammad.' },
      added:         { type: 'array', items: { type: 'string' } },
      removed:       { type: 'array', items: { type: 'string' } },
      already_set:   { type: 'array', items: { type: 'string' }, description: 'Tags to add the ticket had already.' },
      not_set:       { type: 'array', items: { type: 'string' }, description: 'Tags to remove the ticket did not have.' },
      created:       { type: 'array', items: { type: 'string' }, description: 'Tags that did not exist and were created.' },
      tags:          { type: 'array', items: { type: 'string' }, description: 'The ticket\'s tags afterwards.' },
    },
    required:   %w[ticket_id ticket_number url added removed already_set not_set created tags],
  )
  # rubocop:enable Zammad/DetectTranslatableString
  effect      :write
  permission  'ticket.agent'
  offered_in  :mcp
  audiences   :human_agents
  # It removes tags, and a second call with the same names changes nothing more.
  mcp_annotations destructive_hint: true, open_world_hint: false, idempotent_hint: true

  # As the other writes: the ticket's customer who is no agent of its group passes follow_up?, not this.
  loads :ticket, type: ::Ticket, pundit_method: :agent_update_access?, named: true

  def execute
    invalid = invalid_names
    return Service::AI::Tool::Runtime::Result.error('invalid_arguments', invalid) if invalid

    ticket.with_lock do
      change(*plan)
    end
  rescue Invalid => e
    Service::AI::Tool::Runtime::Result.error(e.code, e.message)
  end

  private

  def add_names    = names(:add)
  def remove_names = names(:remove)

  def names(name)
    Array(argument(name)).map { |value| value.to_s.strip }.uniq
  end

  # rubocop:disable Zammad/DetectTranslatableString

  def invalid_names
    all = add_names + remove_names
    return 'Name at least one tag to add or to remove.' if all.empty?
    return "Name at most #{MAX_NAMES} tags to add and #{MAX_NAMES} to remove." if add_names.size > MAX_NAMES || remove_names.size > MAX_NAMES
    return 'A tag name is empty.' if all.any?(&:empty?)
    return 'Tag names hold no commas and no stars.' if all.any? { |value| value.match?(%r{[,*]}) }

    repeated_names
  end

  def repeated_names
    twice = [add_names, remove_names].flat_map { |list| list.group_by(&:downcase).values.select(&:many?).map(&:first) }
    return "#{twice.join(', ')}: named twice, differing by case only. Name each tag once." if twice.any?

    both = add_names.select { |value| remove_names.any? { |other| other.casecmp?(value) } }
    "#{both.join(', ')}: to add and to remove at once. Name each tag once." if both.any?
  end

  # What the call changes, decided before anything changes: a name that matches no tag refuses the whole call.
  def plan
    current = ticket.tag_list
    found   = add_names.index_with { |value| existing_item(value) }
    unknown = found.select { |_value, item| item.nil? }.keys
    refuse_unknown(unknown) if unknown.any? && !may_create?(unknown)

    to_add  = found.map { |value, item| item&.name || value }.uniq
    to_drop = remove_names.map { |value| [value, tag_on_ticket(value, current)] }

    [to_add, to_drop, current, unknown]
  end

  def change(to_add, to_drop, current, unknown)
    added, already_set = to_add.partition { |name| current.exclude?(name) }
    removed            = to_drop.filter_map { |_value, tag| tag }.uniq
    not_set            = to_drop.filter_map { |value, tag| value if tag.nil? }

    added.each   { |name| ticket.tag_add(name, current_user.id) }
    removed.each { |name| ticket.tag_remove(name, current_user.id) }

    receipt(added:, removed:, already_set:, not_set:, created: unknown)
  end

  # The tag of this very name first; else the one that differs only by case. Two of those are told apart by the user.
  def existing_item(value)
    exact = Tag::Item.find_by(name: value)
    return exact if exact

    found = Tag::Item.where(name_downcase: value.downcase).reorder(:name).limit(CANDIDATES + 1).to_a
    return found.first if found.size <= 1

    raise Invalid.new('ambiguous', "Tag \"#{value}\" matches #{Service::AI::Tool::Fields::EntityAttribute.candidates_text(found.map(&:name), found.size, 'tag')}. Use one of them exactly.")
  end

  # As for an addition: the tag of this very name, else the one on the ticket that differs only by case.
  def tag_on_ticket(value, current)
    return current.find { |tag| tag == value } if current.include?(value) || Tag::Item.exists?(name: value)

    found = current.select { |tag| tag.casecmp?(value) }
    return found.first if found.size <= 1

    raise Invalid.new('ambiguous', "Tag \"#{value}\" matches #{Service::AI::Tool::Fields::EntityAttribute.candidates_text(found, found.size, 'tag')} on this ticket. Use one of them exactly.")
  end

  def may_create?(unknown)
    return false if !argument(:create_new_tags)
    return true if unknown.all? { |value| Tag.tag_allowed?(name: value, user_id: current_user.id) }

    raise Invalid.new('not_allowed', "#{unknown.join(', ')}: no such #{'tag'.pluralize(unknown.size)}, and only existing tags may be used here; an admin creates new ones. Nothing was changed.")
  end

  def refuse_unknown(unknown)
    details = unknown.map do |value|
      closest = closest_tags(value)
      closest.any? ? "\"#{value}\" matches no tag; the closest: #{closest.join(', ')}." : "\"#{value}\" matches no tag, and none is close."
    end

    raise Invalid.new('invalid_value', "#{details.join(' ')} Nothing was changed. Ask the user which tag they mean, or call list_tags. " \
                                       'Set create_new_tags only if the user asked for a new tag.')
  end

  # rubocop:enable Zammad/DetectTranslatableString

  # Tags whose names hold the name or one of its words, the most used first.
  def closest_tags(value)
    words = [value.downcase, *value.downcase.scan(%r{[[:alnum:]]{3,}})].uniq
    match = words.map { |word| Tag::Item.where('tag_items.name_downcase LIKE ?', "%#{SqlHelper.quote_like(word)}%") }.reduce(:or)

    match.left_outer_joins(:tags).group(:id).reorder(Arel.sql('COUNT(tags.id) DESC, tag_items.name ASC')).limit(CANDIDATES).pluck(:name)
  end

  def receipt(**changes)
    content = {
      ticket_id:     ticket.id,
      ticket_number: ticket.number,
      url:           Service::AI::Tool::ObjectLink.url(type: 'Ticket', id: ticket.id),
      **changes,
      tags:          ticket.tag_list,
    }

    Service::AI::Tool::Runtime::Result.ok(content, text: text(content))
  end

  # rubocop:disable-next Zammad/DetectTranslatableString
  def text(content)
    lines = { added: 'Added', removed: 'Removed', already_set: 'Already set', not_set: 'Not set, so not removed', created: 'Created as new tags' }
      .filter_map { |key, label| "#{label}: #{content[key].join(', ')}." if content[key].any? }

    ["Ticket #{content[:ticket_number]}:", *lines, "Tags now: #{content[:tags].presence&.join(', ') || 'none'}."].join("\n")
  end
end
