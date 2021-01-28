class SettingAddEmailMarkAndQuote < ActiveRecord::Migration[5.2]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Email - Mark and Quote',
      name:        'ui_ticket_zoom_article_email_mark_and_quote',
      area:        'UI::TicketZoom',
      description: 'Enable if you want to automatically quote selected text.',
      options:     {
        form: [
          {
            display:   '',
            null:      true,
            name:      'ui_ticket_zoom_article_email_mark_and_quote',
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
