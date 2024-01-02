# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class LoopProtectionSettings < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Ticket Trigger Loop Protection Articles per Ticket',
      name:        'ticket_trigger_loop_protection_articles_per_ticket',
      area:        'Ticket::Core',
      description: 'Defines the configuration how many articles can be created in a minute range per ticket.',
      options:     {},
      state:       {
        10  => 10,
        30  => 15,
        60  => 25,
        180 => 50,
        600 => 100,
      },
      preferences: {
        permission: ['admin.ticket'],
        hidden:     true,
      },
      frontend:    false
    )
    Setting.create_if_not_exists(
      title:       'Ticket Trigger Loop Protection Articles Total',
      name:        'ticket_trigger_loop_protection_articles_total',
      area:        'Ticket::Core',
      description: 'Defines the configuration how many articles can be created in a minute range globally.',
      options:     {},
      state:       {
        10  => 30,
        30  => 60,
        60  => 120,
        180 => 240,
        600 => 360,
      },
      preferences: {
        permission: ['admin.ticket'],
        hidden:     true,
      },
      frontend:    false
    )
  end
end
