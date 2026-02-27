# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ObjectManager::Element::Ticket < ObjectManager::Element::Backend

  private

  def authorized?(permission)
    return true if skip_permission
    return false if skip?(permission)

    super
  end

  def skip?(permission)
    record.present? ? skip_with_record?(permission) : skip_without_record?(permission)
  end

  def skip_with_record?(permission)
    case permission
    when 'ticket.agent'
      !agent_record_access?
    when 'ticket.customer'
      agent_record_access? || !customer_record_access?
    else
      false
    end
  end

  def skip_without_record?(permission)
    case permission
    when 'ticket.agent'
      !agent?
    when 'ticket.customer'
      agent?
    else
      false
    end
  end

  def agent?
    return false if act_as_customer && user.permissions?('ticket.customer')

    user.permissions?('ticket.agent')
  end

  def customer?
    user.permissions?('ticket.customer')
  end

  def agent_record_access?
    agent? && user.group_access?(record.group_id, 'read')
  end

  def customer_record_access?
    customer? && record.customer == user
  end
end
