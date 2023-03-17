# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Relation::Owner < FormUpdater::Relation
  private

  def display_name(item)
    "#{item.firstname} #{item.lastname}"
  end

  def relation_type
    ::User
  end
end
