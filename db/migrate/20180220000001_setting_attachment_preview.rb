# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SettingAttachmentPreview < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Sidebar Attachments',
      name:        'ui_ticket_zoom_attachments_preview',
      area:        'UI::TicketZoom::Preview',
      description: 'Enables preview of attachments.',
      options:     {
        form: [
          {
            display:   '',
            null:      true,
            name:      'ui_ticket_zoom_attachments_preview',
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
        prio:       400,
        permission: ['admin.ui'],
      },
      frontend:    true
    )
    Setting.create_if_not_exists(
      title:       'Sidebar Attachments',
      name:        'ui_ticket_zoom_sidebar_article_attachments',
      area:        'UI::TicketZoom::Preview',
      description: 'Enables a sidebar to show an overview of all attachments.',
      options:     {
        form: [
          {
            display:   '',
            null:      true,
            name:      'ui_ticket_zoom_sidebar_article_attachments',
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
        prio:       500,
        permission: ['admin.ui'],
      },
      frontend:    true
    )
  end
end
