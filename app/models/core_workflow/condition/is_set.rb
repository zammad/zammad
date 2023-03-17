# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Condition::IsSet < CoreWorkflow::Condition::Backend
  def match
    return false if object?(Ticket) && @key == 'ticket.owner_id' && value == ['1']
    return false if value == ['']
    return true if value.present?

    false
  end
end
