# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Custom::PendingTime < CoreWorkflow::Custom::Backend
  def saved_attribute_match?
    object?(Ticket)
  end

  def selected_attribute_match?
    object?(Ticket)
  end

  def perform
    result(visibility, 'pending_time')
    result(mandatory, 'pending_time')
  end

  def visibility
    return 'show' if pending?

    'remove'
  end

  def mandatory
    return 'set_mandatory' if pending?

    'set_optional'
  end

  def pending?
    ['pending reminder', 'pending action'].include?(selected&.state&.state_type&.name)
  end
end
