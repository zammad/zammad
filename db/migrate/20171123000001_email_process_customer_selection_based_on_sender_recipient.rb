# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class EmailProcessCustomerSelectionBasedOnSenderRecipient < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Customer selection based on sender and receiver list',
      name:        'postmaster_sender_is_agent_search_for_customer',
      area:        'Email::Base',
      description: 'If the sender is an agent, set the first user in the recipient list as a customer.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'postmaster_sender_is_agent_search_for_customer',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       true,
      preferences: {
        permission: ['admin.channel_email'],
      },
      frontend:    false
    )
  end

end
