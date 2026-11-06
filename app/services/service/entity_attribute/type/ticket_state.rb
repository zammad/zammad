# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::EntityAttribute::Type::TicketState < Service::EntityAttribute::Type::Relation
  handles 'select', relation: 'TicketState'

  private

  # A ticket takes any state, so a workflow may offer one beyond those the forms offer by themselves.
  def workflow_decides?
    true
  end

  def order
    { name: :asc }
  end

  def record_class
    ::Ticket::State
  end

  # As the forms offer them: for a new ticket the states it may start in, otherwise the states an agent may set.
  def candidates
    ::Ticket::State.active.where(id: ::Ticket::State.by_category(new_record? ? :viewable_agent_new : :viewable_agent_edit).select(:id))
  end
end
