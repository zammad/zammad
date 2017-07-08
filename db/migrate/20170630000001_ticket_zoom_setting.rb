class TicketZoomSetting < ActiveRecord::Migration
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

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
      title: 'Note - default visibility',
      name: 'ui_ticket_zoom_article_note_new_internal',
      area: 'UI::TicketZoom',
      description: 'Default visibility for new articles.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'ui_ticket_zoom_article_note_new_internal',
            tag: 'boolean',
            translate: true,
            options: {
              true  => 'internal',
              false => 'public',
            },
          },
        ],
      },
      state: true,
      preferences: {
        prio: 100,
        permission: ['admin.ui'],
      },
      frontend: true
    )
    Setting.create_if_not_exists(
      title: 'Email - subject field',
      name: 'ui_ticket_zoom_article_email_subject',
      area: 'UI::TicketZoom',
      description: 'Use subject field for emails. If disabled, the ticket title will be used as subject.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'ui_ticket_zoom_article_email_subject',
            tag: 'boolean',
            translate: true,
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state: false,
      preferences: {
        prio: 200,
        permission: ['admin.ui'],
      },
      frontend: true
    )
    Setting.create_if_not_exists(
      title: 'Twitter - tweet initials',
      name: 'ui_ticket_zoom_article_twitter_initials',
      area: 'UI::TicketZoom',
      description: 'Add sender initials to end of a tweet.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'ui_ticket_zoom_article_twitter_initials',
            tag: 'boolean',
            translate: true,
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state: true,
      preferences: {
        prio: 300,
        permission: ['admin.ui'],
      },
      frontend: true
    )
  end

end
