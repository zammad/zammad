# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::EntityAttribute::Type::TicketPriority < Service::EntityAttribute::Type::Relation
  handles 'select', relation: 'TicketPriority'

  private

  # A ticket takes any priority, so a workflow may offer one beyond those the forms offer by themselves.
  def workflow_decides?
    true
  end

  def order
    { name: :asc }
  end

  def record_class
    ::Ticket::Priority
  end

  def candidates
    ::Ticket::Priority.where(active: true)
  end
end
