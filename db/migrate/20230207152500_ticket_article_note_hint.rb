# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class TicketArticleNoteHint < ActiveRecord::Migration[6.1]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Hint for adding an article to an existing ticket.',
      name:        'ui_ticket_add_article_hint',
      area:        'UI::TicketZoomArticle',
      description: 'Highlights if the note a user is writing is public or private',
      options:     {},
      state:       {
        # 'note-internal' => 'You are writing an |internal note|, only people of your organization will see it.',
        # 'note-public' => 'You are writing a |public note|.',
        # 'phone-internal' => 'You are writing an |internal phone note|, only people of your organization will see it.',
        # 'phone-public' => 'You are writing a |public phone note|.',
        # ....
      },
      preferences: {
        permission: ['admin.ui'],
      },
      frontend:    true
    )
  end
end
