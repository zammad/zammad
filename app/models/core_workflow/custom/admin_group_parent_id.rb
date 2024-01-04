# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Custom::AdminGroupParentId < CoreWorkflow::Custom::Backend
  def saved_attribute_match?
    selected_attribute_match?
  end

  def selected_attribute_match?
    object?(Group)
  end

  def perform
    result('remove_option', 'parent_id', invalid_groups.map { |x| x.id.to_s })
  end

  private

  def invalid_groups
    invalid_saved_groups | Group.all_max_depth
  end

  def invalid_saved_groups
    return [] if saved_only.blank?

    [saved_only] | saved_only.all_children
  end
end
