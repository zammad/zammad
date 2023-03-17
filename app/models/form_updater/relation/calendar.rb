# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Relation::Calendar < FormUpdater::Relation
  private

  def relation_type
    ::Calendar
  end

  def order
    { name: :asc }
  end
end
