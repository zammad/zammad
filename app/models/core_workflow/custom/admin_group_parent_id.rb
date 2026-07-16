# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Custom::AdminGroupParentId < CoreWorkflow::Custom::Backend
  def saved_attribute_match?
    selected_attribute_match?
  end

  def selected_attribute_match?
    object?(Group)
  end

  def perform
    result('remove_option', 'parent_id', invalid_group_ids.map(&:to_s))
  end

  private

  def invalid_group_ids
    invalid_saved_group_ids | Group.unselectable_as_parent.pluck(:id)
  end

  def invalid_saved_group_ids
    return [] if saved_only.blank?

    [saved_only.id] | saved_only.all_children.pluck(:id)
  end
end
