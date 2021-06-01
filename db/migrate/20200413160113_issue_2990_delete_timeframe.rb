# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue2990DeleteTimeframe < ActiveRecord::Migration[5.2]
  def change
    Setting.create_if_not_exists(
      title:       'Define timeframe where a own created note can get deleted.',
      name:        'ui_ticket_zoom_article_delete_timeframe',
      area:        'UI::TicketZoomArticle',
      description: "Set timeframe in seconds. If it's set to 0 you can delete notes without time limits",
      options:     {},
      state:       600,
      preferences: {
        permission: ['admin.ui']
      },
      frontend:    true
    )
  end
end
