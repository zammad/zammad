# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Relation::Owner < FormUpdater::Relation
  def options_key
    [*super, name_format]
  end

  private

  def display_name(item)
    name = item.fullname(name_format:)
    return name if name.present?
    return item.phone if item.phone.present?

    item.login
  end

  # Read once, so that the options read in the format their key names, also where the setting changes in between.
  def name_format
    @name_format ||= Setting.get('user_name_format')
  end

  # A user's record changes with every login, so the key holds what a name reads in place of the time of that change.
  def options_key_columns
    %i[firstname lastname email phone mobile login]
  end

  def relation_type
    ::User
  end

  def allowed_scope
    Pundit.policy_scope!(current_user, relation_type)
  end
end
