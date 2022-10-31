# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Relation::Group < FormUpdater::Relation
  private

  def relation_type
    ::Group
  end

  def order
    { name: :asc }
  end
end
