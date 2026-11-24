# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A ticket's group, by its path as the UI shows it or its last part: one of the groups the user may move a ticket to,
#   or create a new one in, as Core Workflow offers them in the form.
class Service::EntityAttribute::Type::TicketGroup < Service::EntityAttribute::Type::Relation
  handles 'select', 'tree_select', relation: 'Group'

  # A group's name holds its whole path; people see the parts joined as in the UI.
  def self.path(group)
    group.name.split('::').join(' › ')
  end

  # Groups as a list shows them, each by its last part: a group below another with its parents, a parent that is not
  #   among the groups disabled.
  #
  # @param groups [Array<Group>] the groups to choose from, in the list's order
  # @return [Array<Service::EntityAttribute::Option>]
  def self.option_list_of(groups)
    choosable = groups.to_set(&:id)
    return groups.map { |group| group_option(group, choosable, {}) } if groups.none?(&:parent_id)

    roots, children = tree_of(groups)

    roots.map { |group| group_option(group, choosable, children) }
  end

  # The top groups and each group's children by its ID, in the list's order. Collected by ID, so that a group seen again
  #   costs a lookup instead of a comparison with every group before it.
  def self.tree_of(groups)
    roots     = {}
    children  = {}
    ancestors = ::Group.with_recursive_tree_cte(direction: :up, seed: ::Group.where(id: groups.filter_map(&:parent_id))).index_by(&:id)

    groups.each do |group|
      chain = parent_chain(group, ancestors)
      chain.each_cons(2) { |child, parent| (children[parent.id] ||= {})[child.id] ||= child }
      chain.each { |member| roots[member.id] ||= member if member.parent_id.nil? }
    end

    [roots.values, children.transform_values(&:values)]
  end

  # The group and its parents up to the top, from the parents loaded at once.
  def self.parent_chain(group, ancestors)
    chain = [group]
    while (parent = ancestors[chain.last.parent_id]) && chain.exclude?(parent)
      chain << parent
    end

    chain
  end

  def self.group_option(group, choosable, children)
    Option.new(
      value:    group.id.to_s,
      label:    group.name_last,
      disabled: choosable.exclude?(group.id),
      children: children.fetch(group.id, []).map { |child| group_option(child, choosable, children) },
    )
  end
  private_class_method :tree_of, :parent_chain, :group_option

  # Everything .option_list_of is built from for groups in the order of their names, as a form lists them: the groups to
  #   choose from, and every group as it is now, as a parent that is none of them is listed too.
  #
  # @param group_ids [Array<Integer>] the groups to choose from
  def self.option_list_key_of(group_ids)
    [name, group_ids.sort, groups_version]
  end

  # Every group by the time of its last change. The latest change alone would miss a group whose transaction ends after
  #   a later change of another group.
  def self.groups_version
    ::Group.unscope(:order).pick(Arel.sql("MD5(STRING_AGG(id || ':' || updated_at, ',' ORDER BY id))")) # rubocop:disable Zammad/DetectTranslatableString
  end
  private_class_method :groups_version

  def option_list(allowed: nil)
    self.class.option_list_of(choosable(allowed).to_a)
  end

  # The groups #choosable finds, from the user's access as it is looked up for Core Workflow in the same request.
  def option_list_key(allowed: nil)
    return if unscoped?

    group_ids  = user.group_ids_access(access) | Array(own_value)
    group_ids &= allowed.compact_blank.map(&:to_i) if !allowed.nil?

    self.class.option_list_key_of(group_ids)
  end

  private

  def access
    new_record? ? %w[create] : %w[create change]
  end

  def order
    { name: :asc }
  end

  def convert(value, allowed:)
    Service::EntityAttribute::NameMatch.match(
      value.to_s.squish.gsub(%r{\s*(?:›|::|>)\s*}, ' › '), choosable(allowed).to_a,
      filter: 'group', kind: 'group', label: ->(group) { record_label(group) }, short: :name_last, strict: true
    )
  end

  def record_class
    ::Group
  end

  def candidates
    user.groups_access(access).where(active: true)
  end

  def record_label(group)
    self.class.path(group)
  end
end
