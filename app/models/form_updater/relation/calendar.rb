# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Relation::Calendar < FormUpdater::Relation
  private

  def relation_type
    ::Calendar
  end

  def order
    { name: :asc }
  end

  def allowed_scope
    current_user.permissions?('admin.calendar') ? relation_type.all : relation_type.none
  end
end
