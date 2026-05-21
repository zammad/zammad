# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Relation::TicketState < FormUpdater::Relation
  private

  def relation_type
    ::Ticket::State
  end

  def order
    { name: :asc }
  end

  def default_scope
    relation_type.where(active: true)
  end
end
