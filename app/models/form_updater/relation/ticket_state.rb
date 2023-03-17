# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Relation::TicketState < FormUpdater::Relation
  private

  def relation_type
    ::Ticket::State
  end

  def order
    { name: :asc }
  end
end
