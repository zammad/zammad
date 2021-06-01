# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TicketZoomSetting2 < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(name: 'ui_ticket_zoom_article_new_internal')
    if setting
      setting.title = 'Note - default visibility'
      setting.name = 'ui_ticket_zoom_article_note_new_internal'
      setting.description = 'Default visibility for new articles.'
      setting.preferences[:prio] = 100
      setting.options[:form][0][:name] = 'ui_ticket_zoom_article_note_new_internal'
      setting.save!
    end
    Setting.create_if_not_exists(
      title:       'Note - default visibility',
      name:        'ui_ticket_zoom_article_note_new_internal',
      area:        'UI::TicketZoom',
      description: 'Default visibility for new articles.',
      options:     {
        form: [
          {
            display:   '',
            null:      true,
            name:      'ui_ticket_zoom_article_note_new_internal',
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
        prio:       100,
        permission: ['admin.ui'],
      },
      frontend:    true
    )
    Setting.create_if_not_exists(
      title:       'Email - subject field',
      name:        'ui_ticket_zoom_article_email_subject',
      area:        'UI::TicketZoom',
      description: 'Use subject field for emails. If disabled, the ticket title will be used as subject.',
      options:     {
        form: [
          {
            display:   '',
            null:      true,
            name:      'ui_ticket_zoom_article_email_subject',
            tag:       'boolean',
            translate: true,
            options:   {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       false,
      preferences: {
        prio:       200,
        permission: ['admin.ui'],
      },
      frontend:    true
    )
    Setting.create_if_not_exists(
      title:       'Email - full quote',
      name:        'ui_ticket_zoom_article_email_full_quote',
      area:        'UI::TicketZoom',
      description: 'Enable if you want to quote the full email in your answer. The quoted email will be put at the end of your answer. If you just want to quote a certain phrase, just mark the text and press reply (this feature is always available).',
      options:     {
        form: [
          {
            display:   '',
            null:      true,
            name:      'ui_ticket_zoom_article_email_full_quote',
            tag:       'boolean',
            translate: true,
            options:   {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       false,
      preferences: {
        prio:       220,
        permission: ['admin.ui'],
      },
      frontend:    true
    )
    Setting.create_if_not_exists(
      title:       'Twitter - tweet initials',
      name:        'ui_ticket_zoom_article_twitter_initials',
      area:        'UI::TicketZoom',
      description: 'Add sender initials to end of a tweet.',
      options:     {
        form: [
          {
            display:   '',
            null:      true,
            name:      'ui_ticket_zoom_article_twitter_initials',
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
        prio:       300,
        permission: ['admin.ui'],
      },
      frontend:    true
    )
  end

end
