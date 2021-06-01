# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SettingAddEmailFullQuoteHeader < ActiveRecord::Migration[5.1]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Email - quote header',
      name:        'ui_ticket_zoom_article_email_full_quote_header',
      area:        'UI::TicketZoom',
      description: 'Enable if you want a timestamped reply header to be automatically inserted in front of quoted messages.',
      options:     {
        form: [
          {
            display:   '',
            null:      true,
            name:      'ui_ticket_zoom_article_email_full_quote_header',
            tag:       'boolean',
            translate: true,
            options:   {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       true,
      preferences: {
        prio:       240,
        permission: ['admin.ui'],
      },
      frontend:    true
    )
  end
end
