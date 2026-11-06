# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# One entry of a ticket's history in words, as the ticket view's history words it: a field by its label, its values as
#   stored — a group, state or owner by its name at the time —, an option by its label and a time in the system's
#   time zone. A merged ticket is named only to a reader who may read it (Service::AI::Tool::Runtime::Returned would hand it on).
class Service::AI::Tool::Output::HistoryEntry
  # How an entry names an object other than the ticket.
  ENTITIES = {
    'Ticket::Article'         => 'message',
    'Checklist'               => 'checklist',
    'Checklist::Item'         => 'checklist item',
    'Ticket::SharedDraftZoom' => 'shared draft',
    'Mention'                 => 'mention',
  }.freeze

  # The history's objects whose fields the object manager describes, by the object manager's names.
  OBJECT_MANAGER_OBJECTS = { 'Ticket' => 'Ticket', 'Ticket::Article' => 'TicketArticle' }.freeze

  # The reasons and channels of a notification, as the ticket view names them.
  NOTIFICATION_REASONS = {
    'create'             => 'new ticket',
    'update'             => 'ticket update',
    'reminder_reached'   => 'ticket reminder reached',
    'escalation'         => 'ticket escalation',
    'escalation_warning' => 'ticket escalation warning',
  }.freeze

  TIME_EVENTS = {
    'reminder_reached'   => 'ran because the pending reminder was reached',
    'escalation'         => 'ran because the ticket escalated',
    'escalation_warning' => 'ran because the ticket will escalate soon',
  }.freeze

  attr_reader :entry, :ticket, :users, :attributes, :readable

  # @param users [Hash{Integer => User}] the users of the page, read once
  # @param attributes [Hash{Array(String, String) => ObjectManager::Attribute}] the fields of the page, read once by
  #   .attributes
  # @param readable [#call] whether the reader may see a record
  # @return [Hash] the entry's content, with its description in words
  def self.of(entry, ticket:, users:, attributes:, readable:)
    new(entry, ticket:, users:, attributes:, readable:).content
  end

  # The fields a page of entries changes, read once: a relation under its name with "_id", another under its own.
  #
  # @param entries [Array<History>]
  # @return [Hash{Array(String, String) => ObjectManager::Attribute}] by the object manager's object and the field's name
  def self.attributes(entries)
    names = entries.filter_map do |entry|
      manager_object = OBJECT_MANAGER_OBJECTS[entry.history_object&.name.presence || 'Ticket']
      name           = entry.history_attribute&.name

      [manager_object, name.downcase] if manager_object && name.present?
    end

    names.uniq.group_by(&:first).flat_map do |manager_object, pairs|
      ObjectManager::Attribute
        .where(object_lookup_id: ObjectLookup.by_name(manager_object), name: pairs.flat_map { |_object, name| [name, "#{name}_id"] })
        .map { |attribute| [[manager_object, attribute.name], attribute] }
    end.to_h
  end

  def initialize(entry, ticket:, users:, attributes:, readable:)
    @entry      = entry
    @ticket     = ticket
    @users      = users
    @attributes = attributes
    @readable   = readable
  end

  def content
    @content ||= case action
                 when 'updated', 'set' then change
                 when 'merged_into', 'received_merge' then merge
                 else { action:, description: }
                 end
  end

  private

  def action
    entry.history_type&.name.to_s
  end

  def object
    entry.history_object&.name.to_s
  end

  def attribute
    entry.history_attribute&.name
  end

  def from
    entry.value_from.presence
  end

  def to
    entry.value_to.presence
  end

  def reaction?
    attribute == 'reaction'
  end

  def entity
    ENTITIES.fetch(object, object.demodulize.underscore.humanize.downcase)
  end

  def description
    case action
    when 'created' then created
    when 'added' then "added #{attribute} #{to}".squish
    when 'removed' then removed
    when 'email' then ["sent an email to #{to}", ("(subject: #{from})" if from)].compact.join(' ')
    when 'notification' then notification
    when 'time_trigger_performed' then TIME_EVENTS.fetch(from, 'ran because a time event was reached')
    when 'checklist_item_checked' then "#{to == 'true' ? 'checked' : 'unchecked'} the checklist item: #{from}"
    else [action.humanize.downcase, entity, attribute, from, ('→' if from || to), to].compact.join(' ')
    end
  end

  def created
    return "reacted with #{to} to a message" if reaction?

    case object
    when 'Ticket' then 'created the ticket'
    when 'Ticket::Article' then 'added a message'
    when 'Mention' then "mentioned #{mentioned}"
    when 'Checklist::Item' then "added the checklist item: #{to}"
    when 'Ticket::SharedDraftZoom' then 'saved a shared draft'
    else "created the #{entity}"
    end
  end

  def removed
    return 'removed a reaction' if reaction?

    case object
    when 'Mention' then "removed the mention of #{mentioned}"
    when 'Checklist::Item' then "removed the checklist item: #{to}"
    when 'Ticket', 'Ticket::Article' then "removed #{attribute} #{to}".squish
    else "removed the #{entity}"
    end
  end

  def mentioned
    users[to.to_i]&.fullname || 'a deleted user'
  end

  def notification
    match = to.to_s.match(%r{\A(?<email>.+)\((?<type>[^:()]+):(?<channels>[^()]+)\)\z})
    return "notified #{to}" if !match

    reason = NOTIFICATION_REASONS.fetch(match[:type].split('.').first, match[:type])
    "notified #{match[:email]} (#{reason}: #{match[:channels].split(',').join(', ')})"
  end

  def change
    return { action:, description: to ? "changed the reaction to #{to}" : 'changed a reaction' } if reaction?

    shown_from = value(from)
    shown_to   = value(to)
    prefix     = object == 'Ticket' ? '' : "#{entity} "
    described  = if action == 'set'
                   "set #{prefix}#{label} to #{shown_to || '-'}"
                 else
                   "#{prefix}#{label}: #{shown_from || '-'} → #{shown_to || '-'}"
                 end

    { action:, description: described, field: label, field_key: object_attribute&.name || attribute, from: shown_from, to: shown_to }.compact
  end

  def merge
    other = Ticket.find_by(id: action == 'received_merge' ? entry.id_from : entry.id_to)
    named = other && readable.call(other)
    name  = named ? "ticket #{other.number}" : 'another ticket'

    {
      action:,
      description: action == 'received_merge' ? "merged #{name} into this ticket" : "merged this ticket into #{name}",
      ticket:      ({ type: 'Ticket', id: other.id, number: other.number } if named),
    }.compact
  end

  def object_attribute
    return @object_attribute if defined?(@object_attribute)

    manager_object = OBJECT_MANAGER_OBJECTS[object.presence || 'Ticket']
    @object_attribute = if manager_object && attribute.present?
                          attributes[[manager_object, "#{attribute.downcase}_id"]] || attributes[[manager_object, attribute.downcase]]
                        end
  end

  def relation?
    object_attribute.name.end_with?('_id')
  end

  def label
    object_attribute&.display.presence || attribute.to_s.humanize
  end

  # Relations keep their name at the time; options are keys, times stored as text.
  def value(stored)
    return if stored.nil?
    return stored if !object_attribute || relation?
    return time(stored) if object_attribute.data_type == 'datetime'

    decoded = object_attribute.data_type.start_with?('multi') ? multiple_values(stored) : stored

    shown = Service::EntityAttribute::Type.unscoped(object_attribute).label(decoded)
    shown.is_a?(Array) ? shown.join(', ').presence : shown.to_s.presence || stored
  end

  def multiple_values(stored)
    values = JSON.parse(stored)
    values.is_a?(Array) && values.all?(String) ? values : stored
  rescue JSON::ParserError
    stored
  end

  def time(stored)
    parsed = Time.zone.parse(stored)
    parsed ? Service::AI::Tool::Output.time(parsed) : stored
  rescue ArgumentError
    stored
  end
end
