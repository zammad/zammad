# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ImproveObjectAttributeTicketCustomerIdPermission < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    update_customer_id_attribute
    update_number_attribute
  end

  private

  def update_customer_id_attribute
    attribute = ObjectManager::Attribute.get(name: 'customer_id', object: 'Ticket')

    attribute.screens = {
      create_top: {
        'ticket.agent' => {
          null: false,
        },
      },
      edit:       {},
    }

    # Add 'ticket.customer' permission if not already present
    permission = attribute.data_option[:permission] || []
    if permission.exclude?('ticket.customer')
      permission << 'ticket.customer'
      attribute.data_option[:permission] = permission
    end

    attribute.save!
  end

  def update_number_attribute
    attribute = ObjectManager::Attribute.get(name: 'number', object: 'Ticket')
    attribute.data_option[:display_config] = 'ticket_hook'
    attribute.save!
  end
end
