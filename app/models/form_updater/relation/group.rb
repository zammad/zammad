# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Relation::Group < FormUpdater::Relation
  def options
    options = Service::EntityAttribute::Type::TicketGroup.option_list_of(items.to_a)

    FormUpdater::OptionList.form_options(options, integer: true, tree: options.any? { |option| option.children.any? })
  end

  private

  def relation_type
    ::Group
  end

  def order
    { name: :asc }
  end

  def default_scope
    # Non-agent / admin handling is intentionally deferred — see the
    # FormUpdater::Relation#default_scope TODO.
    return super if !current_user.permissions?('ticket.agent')

    current_user.groups_access('read')
  end

  def allowed_scope
    Pundit.policy_scope!(current_user, relation_type)
  end
end
