class UpdateSettings2 < ActiveRecord::Migration
  def up
    Setting.create_or_update(
      title: 'Additional follow up detection',
      name: 'postmaster_follow_up_search_in',
      area: 'Email::Base',
      description: 'In default the follow up check is done via the subject of an email. With this setting you can add more fields where the follow up ckeck is executed. "References" - Executes follow up check on In-Reply-To or References headers for mails. "Body" - Executes follow up check in mail body. "Attachment" - Executes follow up check in mail attachments.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'postmaster_follow_up_search_in',
            tag: 'checkbox',
            options: {
              'references' => 'References',
              'body'       => 'Body',
              'attachment' => 'Attachment',
            },
          },
        ],
      },
      state: [],
      frontend: false
    )
    Setting.create_or_update(
      title: 'Ticket Hook Position',
      name: 'ticket_hook_position',
      area: 'Ticket::Base',
      description: 'The format of the subject. "Left" means "[Ticket#12345] Some Subject", "Right" means "Some Subject [Ticket#12345]", "None" means "Some Subject" and no ticket number. In the last case you should enable "postmaster_follow_up_search_in" to recognize followups based on email headers and/or body.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'ticket_hook_position',
            tag: 'select',
            options: {
              'left'  => 'Left',
              'right' => 'Right',
              'none'  => 'None',
            },
          },
        ],
      },
      state: 'right',
      frontend: false
    )
  end
end
