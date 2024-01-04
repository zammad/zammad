# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class ObjectManager::Element::Ticket < ObjectManager::Element::Backend

  private

  def authorized?(permission)
    return true if skip_permission
    return false if skip?(permission)

    super
  end

  def skip?(permission)
    return true if agent_in_general_view?(permission)
    return true if agent_access_missing?(permission)

    authorized_customer_and_agent?(permission)
  end

  def agent_in_general_view?(permission)
    record.blank? && permission == 'ticket.customer' && agent?
  end

  def agent_access_missing?(permission)
    record.present? && permission == 'ticket.agent' && agent? && !read_access?
  end

  def authorized_customer_and_agent?(permission)
    record.present? && permission == 'ticket.customer' && agent? && read_access?
  end

  def agent?
    user.permissions?('ticket.agent')
  end

  def read_access?
    user.group_access?(record.group_id, 'read')
  end
end
