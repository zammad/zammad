# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SettingAddTicketAgentDefaultNotifications < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_or_update(
      title:       'Default Ticket Agent Notifications',
      name:        'ticket_agent_default_notifications',
      area:        'Ticket::Core',
      description: 'Define the default agent notifications for new users.',
      options:     {
        form: [
          {},
        ],
      },
      preferences: {
        authentication: true,
        permission:     ['admin.ticket'],
      },
      state:       {
        create:           {
          criteria: {
            owned_by_me:     true,
            owned_by_nobody: true,
            subscribed:      true,
            no:              false,
          },
          channel:  {
            email:  true,
            online: true,
          }
        },
        update:           {
          criteria: {
            owned_by_me:     true,
            owned_by_nobody: true,
            subscribed:      true,
            no:              false,
          },
          channel:  {
            email:  true,
            online: true,
          }
        },
        reminder_reached: {
          criteria: {
            owned_by_me:     true,
            owned_by_nobody: false,
            subscribed:      false,
            no:              false,
          },
          channel:  {
            email:  true,
            online: true,
          }
        },
        escalation:       {
          criteria: {
            owned_by_me:     true,
            owned_by_nobody: false,
            subscribed:      false,
            no:              false,
          },
          channel:  {
            email:  true,
            online: true,
          }
        }
      },
      frontend:    true
    )
  end
end
