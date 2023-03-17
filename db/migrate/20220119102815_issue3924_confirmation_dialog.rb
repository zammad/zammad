# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue3924ConfirmationDialog < ActiveRecord::Migration[6.0]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Note - visibility confirmation dialog',
      name:        'ui_ticket_zoom_article_visibility_confirmation_dialog',
      area:        'UI::TicketZoom',
      description: 'Defines if the agent has to accept a confirmation dialog when changing the article visibility to "public".',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'ui_ticket_zoom_article_visibility_confirmation_dialog',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       false,
      preferences: {
        prio:       100,
        permission: ['admin.ui'],
      },
      frontend:    true
    )
  end
end
