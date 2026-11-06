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

    roots     = []
    children  = {}
    ancestors = ::Group.with_recursive_tree_cte(direction: :up, seed: ::Group.where(id: groups.filter_map(&:parent_id))).index_by(&:id)

    groups.each do |group|
      chain = parent_chain(group, ancestors)
      chain.each_cons(2) { |child, parent| children[parent.id] = [*children[parent.id]] | [child] }
      chain.each { |member| roots |= [member] if member.parent_id.nil? }
    end

    roots.map { |group| group_option(group, choosable, children) }
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
  private_class_method :parent_chain, :group_option

  def option_list(allowed: nil)
    self.class.option_list_of(choosable(allowed).to_a)
  end

  private

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
    user.groups_access(new_record? ? %w[create] : %w[create change]).where(active: true)
  end

  def record_label(group)
    self.class.path(group)
  end
end
