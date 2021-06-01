# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class UiTicketZoomArticleNewInternal < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Define default visibility of new a new article',
      name:        'ui_ticket_zoom_article_new_internal',
      area:        'UI::TicketZoom',
      description: 'Set default visibility of new a new article.',
      options:     {
        form: [
          {
            display:   '',
            null:      true,
            name:      'ui_ticket_zoom_article_new_internal',
            tag:       'boolean',
            translate: true,
            options:   {
              true  => 'internal',
              false => 'public',
            },
          },
        ],
      },
      state:       true,
      preferences: {
        prio:       1,
        permission: ['admin.ui'],
      },
      frontend:    true
    )
  end
end
