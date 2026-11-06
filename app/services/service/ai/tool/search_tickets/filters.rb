# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The filters of a ticket search, given by name as people and other systems know them, resolved for the user at call
#   time: only to records the user may see, and to an error that names the candidates or the valid values where a name
#   fits several records or none. Names are matched without regard to case and spaces: exactly first, then by a part
#   that fits one record only.
class Service::AI::Tool::SearchTickets::Filters
  NOBODY_ID = Service::EntityAttribute::NameMatch::NOBODY_ID

  Invalid = Service::AI::Tool::Fields::EntityAttribute::Invalid

  attr_reader :user, :ids, :descriptions

  # @param user [User] as whom the search runs
  # @param arguments [Hash] the tool's arguments, with string keys
  # @raise [Invalid]
  def initialize(user:, arguments:)
    @user         = user
    @ids          = {}
    @descriptions = []

    resolve(arguments)
  end

  # Filters that exclude each other, such as a state that is not in the state category, match no ticket.
  def match_nothing?
    ids.values.any?(&:empty?)
  end

  # For Ticket.search, on its database and its Elasticsearch path alike.
  def conditions
    ids.to_h { |column, values| ["ticket.#{column}", { operator: 'is', value: values }] }
  end

  # For the database's check of the search's hits, as the index can lag behind.
  def apply(relation)
    relation.where(ids)
  end

  private

  def resolve(arguments)
    customer(text(arguments['customer']))
    organization(text(arguments['organization']))
    states(Array(arguments['state']).filter_map { |value| text(value) }, text(arguments['state_type_category']))
    owner(text(arguments['owner']))
    group(text(arguments['group']))
    priority(text(arguments['priority']))
  end

  def text(value)
    value.to_s.squish.presence
  end

  def add(column, values, description)
    ids[column] = values
    descriptions << description
  end

  def customer(value)
    return if value.nil?

    found = matching { Service::EntityAttribute::NameMatch.user(value, users, filter: 'customer', kind: 'user') }
    add(:customer_id, [found.id], "customer #{Service::AI::Tool::Fields::EntityAttribute.user_description(found)}")
  end

  def owner(value)
    return if value.nil?

    case value.downcase
    when 'me'
      add(:owner_id, [user.id], "owner #{user.fullname} (you)")
    when 'nobody'
      add(:owner_id, [NOBODY_ID], 'owner nobody')
    else
      found = matching { Service::EntityAttribute::NameMatch.user(value, agents, filter: 'owner', kind: 'agent') }
      add(:owner_id, [found.id], "owner #{Service::AI::Tool::Fields::EntityAttribute.user_description(found)}")
    end
  end

  def organization(value)
    return if value.nil?

    scope = OrganizationPolicy::Scope.new(user, Organization).resolve
    found = matching { Service::EntityAttribute::NameMatch.organization(value, scope, filter: 'organization', kind: 'organization') }

    add(:organization_id, [found.id], "organization #{found.name}")
  end

  def states(names, category)
    return if names.empty? && category.nil?

    all   = names.any? ? Ticket::State.reorder(:id).to_a : []
    hint  = 'Use the full name, or pass several.' # rubocop:disable Zammad/DetectTranslatableString
    found = names.map { |name| matching(hint:) { Service::EntityAttribute::NameMatch.match(name, all, filter: 'state', kind: 'state', label: :name) } }
    ids   = found.map(&:id)
    ids  &= Ticket::State.by_category_ids(category) if category && found.any?
    ids   = Ticket::State.by_category_ids(category) if found.empty?

    add(:state_id, ids, [("state category #{category}" if category), ("state #{found.map(&:name).join(', ')}" if found.any?)].compact.join(' · '))
  end

  def group(value)
    return if value.nil?

    groups = Group.where(id: user.group_ids_access('read')).reorder(:id).to_a
    found  = matching { Service::EntityAttribute::NameMatch.match(value.gsub(%r{\s*(?:›|::|>)\s*}, ' › '), groups, filter: 'group', kind: 'group', label: ->(group) { Service::AI::Tool::Fields::EntityAttribute.group_name(group) }, short: :name_last) }

    add(:group_id, [found.id], "group #{Service::AI::Tool::Fields::EntityAttribute.group_name(found)}")
  end

  def priority(value)
    return if value.nil?

    found = matching { Service::EntityAttribute::NameMatch.match(value, Ticket::Priority.reorder(:id).to_a, filter: 'priority', kind: 'priority', label: :name) }
    add(:priority_id, [found.id], "priority #{found.name}")
  end

  def matching(...)
    Service::AI::Tool::Fields::EntityAttribute.matching(...)
  end

  # The users the user may see, without the system user.
  def users
    UserPolicy::Scope.new(user, User).resolve.where.not(id: NOBODY_ID)
  end

  # Agents who left still own their tickets, so the inactive ones count too; User.with_permissions takes active users only.
  def agents
    users.where(id: User.joins(:roles_users).where(roles_users: { role_id: Role.with_permissions('ticket.agent').select(:id) }).select(:id))
  end
end
