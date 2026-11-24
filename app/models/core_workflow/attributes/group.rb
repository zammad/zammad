# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Attributes::Group < CoreWorkflow::Attributes::Base
  def values
    group_ids.presence || ['']
  end

  def customer_ticket_create_group_ids
    Setting.get('customer_ticket_create_group_ids')
  end

  def group_ids
    @group_ids ||= if agent_view?
                     group_ids_agent
                   elsif customer_view?
                     groups_customer.pluck(:id)
                   else
                     groups_default.pluck(:id)
                   end
  end

  def agent_view?
    @attributes.payload_class == Ticket && @attributes.user.permissions?('ticket.agent')
  end

  def customer_view?
    @attributes.payload_class == Ticket && @attributes.user.permissions?('ticket.customer') && @attributes.payload['screen'] == 'create_middle' && customer_ticket_create_group_ids.present?
  end

  # The lookup the field layer runs for the group field as well, so that a request which asks both runs it once.
  def group_ids_agent
    access = @attributes.payload['screen'] == 'create_middle' ? %w[create] : %w[create change]

    @attributes.user.group_ids_access(access).sort
  end

  def groups_customer
    Group.where(id: customer_ticket_create_group_ids, active: true)
  end

  def groups_default
    Group.where(active: true)
  end
end
