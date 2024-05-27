# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Relation::Group < FormUpdater::Relation
  attr_accessor :lookup_parent_child_groups, :root_groups

  def initialize(...)
    super

    @root_groups = []
    @lookup_parent_child_groups = {}
  end

  def options
    # If we have no child groups in the current list, we can handle it in a easy way, because
    # we have only a flat structure.
    if items.none? { |item| item.parent_id.present? }
      return items.map do |item|
        { value: item.id, label: display_name(item) }
      end
    end

    options_tree_preparation
    options_tree
  end

  private

  def relation_type
    ::Group
  end

  def order
    { name: :asc }
  end

  def display_name(item)
    item.name_last
  end

  def usable_group_ids
    @usable_group_ids ||= items.pluck(:id)
  end

  def options_tree_preparation
    items.each do |item|
      next if root_group?(item)

      prepare_lookup_parent_child_groups(item)
    end
  end

  def prepare_lookup_parent_child_groups(item)
    last_item = item

    item.all_parents.each do |parent|
      if !lookup_parent_child_groups.key?(parent.id)
        lookup_parent_child_groups[parent.id] = []
      end

      parent_child_group?(parent, last_item)

      last_item = parent

      root_group?(parent)
    end
  end

  def parent_child_group?(parent, item)
    return false if lookup_parent_child_groups[parent.id].include?(item)

    lookup_parent_child_groups[parent.id].push(item)

    true
  end

  def root_group?(item)
    return false if item.parent_id.present? || root_groups.include?(item)

    root_groups.push(item)

    true
  end

  def options_tree(groups = root_groups)
    groups.each_with_object([]) do |group, options|
      children = []
      if lookup_parent_child_groups.key?(group.id)
        children = options_tree(lookup_parent_child_groups[group.id])
      end

      options.push(option_array_resolved(display_name(group), group.id, usable_group_ids.exclude?(group.id), children))
    end
  end

  def option_array_resolved(label, value, disabled, children)
    resolved_option = {
      value:    value,
      label:    label,
      disabled: disabled,
    }

    if children.any?
      resolved_option[:children] = children
    end

    resolved_option
  end
end
