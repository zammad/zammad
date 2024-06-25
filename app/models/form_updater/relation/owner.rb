# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Relation::Owner < FormUpdater::Relation
  private

  def display_name(item)
    return item.fullname if item.fullname.present?
    return item.phone if item.phone.present?

    item.login
  end

  def relation_type
    ::User
  end
end
