# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Custom::AdminShowGroupListForAgents < CoreWorkflow::Custom::Backend
  def saved_attribute_match?
    selected_attribute_match?
  end

  def selected_attribute_match?
    @selected_attribute_match ||= object?(User) || object?(Role)
  end

  def perform
    return perform_role if object?(Role)

    perform_user
  end

  def perform_role
    result(perform_role_show_group_ids?, 'group_ids')
  end

  def perform_role_show_group_ids?
    # In case the permission_ids are not included in the params, we want to check against the saved object
    #   permission_ids too, as those are the ones currently set for the role, and thus determine the visibility of the
    #   group_ids field.
    return 'show' if Array.wrap(params['permission_ids'] || saved.permission_ids).map(&:to_i).include?(Permission.find_by(name: 'ticket.agent').id)

    'remove'
  end

  def perform_user
    result(perform_user_show_group_ids?, 'group_ids')
  end

  def perform_user_show_group_ids?
    # In case the role_ids are not included in the params, we want to check against the saved object role_ids too,
    #   as those are the ones currently set for the user, and thus determine the visibility of the group_ids field.
    return 'show' if Array.wrap(params['role_ids'] || saved.role_ids).map(&:to_i).intersect?(Role.with_permissions('ticket.agent').pluck(:id))

    'remove'
  end
end
