# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Pr5952FixTypos < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    migrate_schedulers
    migrate_settings
  end

  private

  def migrate_schedulers
    [
      {
        method: 'ExternalCredential::Exchange.refresh_token',
        update: { name: 'Update Exchange OAuth2 token.' },
      },
    ].each do |migration|
      Scheduler.find_by(method: migration[:method])&.update(migration[:update])
    end
  end

  def migrate_settings
    [
      {
        name:   'websocket_backend',
        update: {
          title:       'WebSocket backend',
          description: 'Defines how to reach WebSocket server. "websocket" is default on production, "websocketPort" is for CI.',
        }
      },
      {
        name:   'websocket_port',
        update: {
          title:       'WebSocket port',
          description: 'Defines the port of the WebSocket server.',
        }
      },
      {
        name:   'core_workflow_ajax_mode',
        update: {
          description: 'Defines if the core workflow communication should run over AJAX instead of WebSocket.',
        }
      },
      {
        name:   '0900_postmaster_filter_bounce_follow_up_check',
        update: {
          description: 'Defines postmaster filter to identify postmaster bounces; and handles them as follow-up of the original tickets.',
        }
      },
      {
        name:   'ui_ticket_zoom_article_delete_timeframe',
        update: {
          description: "Set timeframe in seconds. If it's set to 0 you can delete notes without time limits.",
        }
      },
      {
        name:   'ui_desktop_beta_switch',
        update: {
          title: 'Desktop BETA UI Switch',
        }
      },
      {
        name:   'ui_desktop_beta_switch_admin_menu',
        update: {
          title: 'Desktop BETA UI Switch Admin Menu',
        }
      },
      {
        name:   'ui_desktop_beta_switch_role_ids',
        update: {
          title:       'Desktop BETA UI Switch Roles',
          description: 'Defines which roles are allowed to access the desktop BETA UI switch.',
        }
      },
      {
        name:   'session_timeout',
        update: {
          options: {
            form: [
              {
                display:   'Default',
                null:      false,
                name:      'default',
                tag:       'select',
                options:   options,
                translate: true,
              },
              {
                display:   'Admin interface',
                null:      false,
                name:      'admin',
                tag:       'select',
                options:   options,
                translate: true,
                note:      'admin',
              },
              {
                display:   'Agent tickets',
                null:      false,
                name:      'ticket.agent',
                tag:       'select',
                options:   options,
                translate: true,
                note:      'ticket.agent',
              },
              {
                display:   'Customer tickets',
                null:      false,
                name:      'ticket.customer',
                tag:       'select',
                options:   options,
                translate: true,
                note:      'ticket.customer',
              },
            ],
          },
        },
      }
    ].each do |migration|
      Setting.find_by(name: migration[:name])&.update(migration[:update])
    end
  end

  def options
    [
      { value: '0', name: 'disabled' },
      { value: 1.hour.seconds.to_s, name: '1 hour' },
      { value: 2.hours.seconds.to_s, name: '2 hours' },
      { value: 1.day.seconds.to_s, name: '1 day' },
      { value: 7.days.seconds.to_s, name: '1 week' },
      { value: 14.days.seconds.to_s, name: '2 weeks' },
      { value: 21.days.seconds.to_s, name: '3 weeks' },
      { value: 28.days.seconds.to_s, name: '4 weeks' },
    ]
  end

end
