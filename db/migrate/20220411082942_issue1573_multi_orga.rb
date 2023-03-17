# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue1573MultiOrga < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_user_organization
    remove_ticket_organization_readonly
    add_organization_to_overview
    fix_organization_screens
  end

  def add_user_organization
    UserInfo.current_user_id = 1
    ObjectManager::Attribute.add(
      force:       true,
      object:      'User',
      name:        'organization_ids',
      display:     'Secondary organizations',
      data_type:   'autocompletion_ajax',
      data_option: {
        multiple:      true,
        nulloption:    true,
        null:          true,
        relation:      'Organization',
        item_class:    'formGroup--halfSize',
        display_limit: 3,
      },
      editable:    false,
      active:      true,
      screens:     {
        signup:          {},
        invite_agent:    {},
        invite_customer: {
          '-all-' => {
            null: true,
          },
        },
        edit:            {
          '-all-' => {
            null: true,
          },
        },
        create:          {
          '-all-' => {
            null: true,
          },
        },
        view:            {
          '-all-' => {
            shown: true,
          },
        },
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    901,
    )
  end

  def remove_ticket_organization_readonly
    attribute = ObjectManager::Attribute.find_by(name: 'organization_id', object_lookup_id: ObjectLookup.by_name('Ticket'))
    attribute.data_type = 'autocompletion_ajax_customer_organization'
    attribute.data_option.delete(:readonly)
    attribute.data_option[:permission] = ['ticket.agent', 'ticket.customer']
    attribute.save!(validate: false)
  end

  def overview_customer_index(overview, view)
    overview.view[view].index('customer') || (overview.view[view].count - 1)
  end

  def add_organization_to_overview
    overview = Overview.find_by(link: 'my_organization_tickets')
    return if overview.blank?

    %w[d s m].each do |view|
      next if overview.view[view].blank?
      next if overview.view[view].include?('organization')

      idx = overview_customer_index(overview, view)
      overview.view[view].insert(idx + 1, 'organization')
    end
    overview.save!
  end

  def fix_organization_screens
    ObjectManager::Attribute.where(object_lookup_id: ObjectLookup.by_name('Organization'), editable: false).each do |attribute|
      customer = false
      if attribute.name == 'name'
        customer = true
      end

      attribute.screens[:view] = {
        'ticket.agent'    => {
          shown: true,
        },
        'ticket.customer' => {
          shown: customer,
        }
      }
      attribute.save!
    end
  end
end
